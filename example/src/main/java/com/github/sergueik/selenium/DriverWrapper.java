package com.github.sergueik.selenium;

import java.net.MalformedURLException;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

import org.openqa.selenium.Capabilities;
import org.openqa.selenium.NoSuchSessionException;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.firefox.FirefoxDriver;
import org.openqa.selenium.remote.RemoteWebDriver;
import org.openqa.selenium.remote.UnreachableBrowserException;

// based: https://github.com/mkolisnyk/V08632/blob/master/src/main/java/com/sample/framework/Driver.java
// which exercises thread isolation from Packt's Automated UI Testing in Android
// see also https://www.swtestacademy.com/selenium-parallel-tests-grid-testng/
// http://www.jitendrazaa.com/blog/java/performing-load-testing-in-salesforce-using-selenium-and-testng
// https://automated-testing.info/t/parallelnyj-zapusk-v-neskolkih-brauzerah-selenide-testng-gradle-allure-kakoj-normalnyj-pattern/21914/19
// https://github.com/iljapavlovs/selenium-testng-allure-maven
// https://github.com/kowalcj0/parallel-selenium-with-testng

public class DriverWrapper extends RemoteWebDriver {

	private static String hubUrl = null;
	private static Boolean debug = false;

	private DriverWrapper() {
	}

	private DriverWrapper(String hubUrl) {
		DriverWrapper.hubUrl = hubUrl;
	}

	public static void setHubUrl(String value) {
		DriverWrapper.hubUrl = value;
	}

	public static void setDebug(Boolean value) {
		DriverWrapper.debug = value;
	}

	private static ConcurrentHashMap<String, RemoteWebDriver> driverInventory = new ConcurrentHashMap<String, RemoteWebDriver>();

	public static List<String> getDriverInventoryDump() {
		return driverInventory.entrySet().stream()
				.map(_entry -> String.format("%s => %s %d", _entry.getKey(),
						_entry.getValue().getClass(), _entry.getValue().hashCode()))
				.collect(Collectors.toList());
	}

	@SuppressWarnings("deprecation")
	public static void add(String browser, Capabilities capabilities) {
		RemoteWebDriver driver = null;
		if (browser.trim().equalsIgnoreCase("remote")) {
			try {
				driver = new RemoteWebDriver(new URL(hubUrl), capabilities);
			} catch (MalformedURLException | UnreachableBrowserException
					| NoSuchSessionException e) { // hub down ?
				System.err.println("Exception: " + e.toString());
				// org.openqa.selenium.NoSuchSessionException:
				// Tried to run command without establishing a connection
				// throw new RuntimeException(e.getCause());
				throw new RuntimeException(e);
			}
			driverInventory.put(getThreadName(), driver);
		} else {
			if (browser == "firefox") {
				driver = new FirefoxDriver(capabilities);
			}

			if (browser == "chrome") {
				driver = new ChromeDriver(capabilities);
			}
			driverInventory.put(getThreadName(), driver);
		}
	}

	public static RemoteWebDriver current() {
		return driverInventory.get(getThreadName());
	}

	private static String getThreadName() {
		return Thread.currentThread().getName() + "-"
				+ Thread.currentThread().getId();
	}
}
