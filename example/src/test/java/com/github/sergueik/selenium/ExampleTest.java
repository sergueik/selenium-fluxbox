package com.github.sergueik.selenium;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.CoreMatchers.containsString;
import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.Matchers.greaterThan;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.CoreMatchers.notNullValue;
import static org.hamcrest.CoreMatchers.nullValue;

import org.hamcrest.MatcherAssert;

import java.util.regex.Pattern;
import static org.testng.Assert.assertTrue;

import java.io.File;
import java.nio.file.Paths;

//reserved for turning on Selenide and Allure
//import com.codeborne.selenide.*;
//import static com.codeborne.selenide.Selenide.$;
//import static com.codeborne.selenide.Selenide.open;
//import com.codeborne.selenide.logevents.SelenideLogger;
//import io.qameta.allure.selenide.AllureSelenide;

// https://seleniumhq.github.io/selenium/docs/api/java/org/openqa/selenium/support/ui/FluentWait.html#pollingEvery-java.time.Duration-
// NOTE: needs java.time.Duration not the org.openqa.selenium.support.ui.Duration;
import java.time.Duration;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;

import org.openqa.selenium.Alert;
import org.openqa.selenium.By;
import org.openqa.selenium.JavascriptExecutor;
import org.openqa.selenium.Keys;
import org.openqa.selenium.TakesScreenshot;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.chrome.ChromeOptions;
import org.openqa.selenium.interactions.Actions;
import org.openqa.selenium.remote.DesiredCapabilities;
import org.openqa.selenium.remote.RemoteWebDriver;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;

import org.testng.annotations.AfterClass;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.DataProvider;
import org.testng.annotations.Test;

// based on: https://github.com/sergueik/selenium_tests/blob/master/src/test/java/com/github/sergueik/selenium/ParallelMultiBrowserTest.java
// based on https://github.com/tw1911/test1/blob/master/src/test/java/com/tw1911/test1/GoogleSearchTests.java
public class ExampleTest {

	private static String osName = getOSName();
	private static final boolean remote = true;
	private static final boolean headless = Boolean
			.parseBoolean(System.getenv("HEADLESS"));
	private static final String searchString = "Тестовое задание";

	// You cannot use primitive types as generic type arguments.
	//
	private static ConcurrentHashMap<Long, WebDriver> drivers = new ConcurrentHashMap<Long, WebDriver>();

	private static Boolean debug = false;

	public int scriptTimeout = 5;
	public int flexibleWait = 30;
	public int implicitWait = 1;
	public int pollingInterval = 500;
	@SuppressWarnings("unused")
	private static long highlightInterval = 100;

	// NOTE: pass distinct base url, element locators to parallel tests for
	// debugging
	@DataProvider(name = "same-browser", parallel = true)
	public Object[][] provideSameBrowser() throws Exception {
		return new Object[][] {
				{ "chrome", "https://www.google.com/?hl=ru", "input[name*='q']" },
				{ "chrome", "https://www.google.com/?hl=ko", "input[name='q']" }, };
	}

	@DataProvider(name = "different-browser", parallel = true)
	public Object[][] provideDiffernetBrowser() throws Exception {
		return new Object[][] {
				{ "chrome", "https://www.google.com/?hl=ru", "input[name*='q']" },
				{ "firefox", "https://www.google.com/?hl=ko", "input[name='q']" }, };
	}

	private static final Map<String, String> browserDrivers = new HashMap<>();
	static {
		browserDrivers.put("chrome",
				osName.equals("windows") ? "chromedriver.exe" : "chromedriver");
		browserDrivers.put("firefox",
				osName.equals("windows") ? "geckodriver.exe" : "geckodriver");
		browserDrivers.put("edge", "MicrosoftWebDriver.exe");
	}

	private static final Map<String, String> browserDriverSystemProperties = new HashMap<>();
	static {
		browserDriverSystemProperties.put("chrome", "webdriver.chrome.driver");
		browserDriverSystemProperties.put("firefox", "webdriver.gecko.driver");
		browserDriverSystemProperties.put("edge", "webdriver.edge.driver");
	}

	@Test(enabled = true, dataProvider = "same-browser", threadPoolSize = 2)
	public void googleSearch1Test(String browser, String baseURL,
			String cssSelector) {

		WebDriver driver = getWebDriver(browser, remote);

		driver.get(baseURL);

		if (debug) {
			System.err.println("Thread id: " + Thread.currentThread().getId() + "\n"
					+ "Driver hash code: " + driver.hashCode() + "\n"
					+ "Driver hash code: " + DriverWrapper.current().hashCode());
		}
		driver.get(baseURL);

		Actions actions = new Actions(driver);

		driver.manage().timeouts().setScriptTimeout(scriptTimeout,
				TimeUnit.SECONDS);

		TakesScreenshot screenshot = ((TakesScreenshot) driver);
		JavascriptExecutor js = ((JavascriptExecutor) driver);

		WebDriverWait wait = new WebDriverWait(driver, flexibleWait);

		wait.pollingEvery(Duration.ofMillis(pollingInterval));

		wait.pollingEvery(Duration.ofMillis(pollingInterval));

		driver.manage().timeouts().implicitlyWait(implicitWait, TimeUnit.SECONDS);

		WebElement element = wait.until(ExpectedConditions
				.visibilityOf(driver.findElement(By.cssSelector(cssSelector))));
		if (debug) {
			System.err.println("Thread id: " + Thread.currentThread().getId() + "\n"
					+ "Driver hash code: " + driver.hashCode() + "\n"
					+ "WebDriveWait hash code: " + wait.hashCode() + "\n"
					+ "Web Element hash code: " + element.hashCode());
		}
		// TODO: element.setAttribute("value", searchString );
		element.sendKeys(searchString);
		/*
		element = wait.until(
				ExpectedConditions.visibilityOf(driver.findElement(
						By.xpath(String.format("//input[@name = '%s']", "btnK"))))); // [@type='submit']
						click();
						*/

		element = wait.until(
				// TODO; exercise locale - specific button assert "Поиск в Google" |
				// "Google Search"
				ExpectedConditions.visibilityOf(driver.findElement(By.xpath(
						String.format("//input[contains(@value, '%s')]", "Google")))));
		element.click();
		element = wait.until(ExpectedConditions
				.visibilityOf(driver.findElement(By.id("resultStats"))));
		assertThat(element, notNullValue());
	}

	@Test(enabled = false, dataProvider = "different-browser", threadPoolSize = 2)
	public void googleSearch2Test(String browser, String baseURL,
			String cssSelector) {

		WebDriver driver = getWebDriver(browser, remote);

		if (debug) {
			System.err.println("Thread id: " + Thread.currentThread().getId() + "\n"
					+ "Driver inventory: "
					+ DriverWrapper.getDriverInventoryDump().toString() + "\n"
					+ "Driver hash code: " + driver.hashCode());
		}
		driver.get(baseURL);
		Actions actions = new Actions(driver);

		driver.manage().timeouts().setScriptTimeout(scriptTimeout,
				TimeUnit.SECONDS);

		TakesScreenshot screenshot = ((TakesScreenshot) driver);
		JavascriptExecutor js = ((JavascriptExecutor) driver);

		WebDriverWait wait = new WebDriverWait(driver, flexibleWait);
		wait.pollingEvery(Duration.ofMillis(pollingInterval));

		driver.manage().timeouts().implicitlyWait(implicitWait, TimeUnit.SECONDS);

		WebElement element = driver.findElement(By.cssSelector(cssSelector));
		if (debug) {
			System.err.println("Thread id: " + Thread.currentThread().getId() + "\n"
					+ "Driver inventory: "
					+ DriverWrapper.getDriverInventoryDump().toString() + "\n"
					+ "Driver hash code: " + driver.hashCode() + "\n"
					+ "Web Element hash code: " + element.hashCode());
		}
		element.sendKeys(searchString + Keys.RETURN);
		element = wait.until(ExpectedConditions
				.visibilityOf(driver.findElement(By.id("resultStats"))));
		assertThat(element, notNullValue());
		assertTrue(element.getText().matches("^.*\\b(?:\\d+)\\b.*$"));

	}

	@BeforeClass
	public static void setUp() {
		if (remote) {
			DriverWrapper.setHubUrl("http://127.0.0.1:4444/wd/hub");
		}
	}

	@AfterMethod
	public void afterMethod() {
		try {
			Thread.sleep(100);
		} catch (InterruptedException e1) {
		}
		// driver.get("about:blank");
		for (Long threadId : drivers.keySet()) {
			WebDriver driver = drivers.get(threadId);

			if (driver != null) {
				try {
					driver.close();
					driver.quit();
					drivers.put(threadId, null);
				} catch (NullPointerException e) {
					System.err.println("Exception (ignored): " + e.getMessage());
				} catch (Exception e) {
					System.err.println(
							"Exception (ignored): " + e.getClass() + " " + e.getMessage());
				}
			}
		}
	}

	@AfterClass
	public static void tearDown() {
		// SelenideLogger.removeListener("allure");
	}

	// Utilities
	private static String getOSName() {
		if (osName == null) {
			osName = System.getProperty("os.name").toLowerCase();
			if (osName.startsWith("windows")) {
				osName = "windows";
			}
		}
		return osName;
	}

	private WebDriver getWebDriver(String browser, Boolean remote) {

		System.err.println("Launching " + browser + (remote ? " remotely" : ""));
		System.setProperty(browserDriverSystemProperties.get(browser),
				Paths.get(System.getProperty("user.home")).resolve("Downloads")
						.resolve(browserDrivers.get(browser)).toAbsolutePath().toString());
		if (browser.equals("chrome")) {
			DesiredCapabilities capabilities = DesiredCapabilities.chrome();
			ChromeOptions chromeOptions = new ChromeOptions();
			// options for headless
			if (headless) {
				for (String optionAgrument : (new String[] { "headless",
						"window-size=1200x800" })) {
					chromeOptions.addArguments(optionAgrument);
				}
			}
			capabilities
					.setBrowserName(DesiredCapabilities.chrome().getBrowserName());
			DriverWrapper.add(remote ? "remote" : "chrome", capabilities);
		} else if (browser.equals("firefox")) {
			System
					.setProperty("webdriver.firefox.bin",
							osName.equals("windows") ? new File(
									"c:/Program Files (x86)/Mozilla Firefox/firefox.exe")
											.getAbsolutePath()
									: "/usr/bin/firefox");
			DesiredCapabilities capabilities = DesiredCapabilities.firefox();
			if (!remote) {
				capabilities.setCapability("marionette", false);
			}
			DriverWrapper.add(remote ? "remote" : "firefox", capabilities);
		}
		DriverWrapper.setDebug(debug);
		if (debug) {
			System.err.println("Driver inventory: "
					+ DriverWrapper.getDriverInventoryDump().toString());
		}
		WebDriver driver = DriverWrapper.current();
		drivers.put(Thread.currentThread().getId(), driver);
		return driver;
	}
}
