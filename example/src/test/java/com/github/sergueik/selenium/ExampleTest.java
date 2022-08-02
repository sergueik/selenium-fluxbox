package com.github.sergueik.selenium;

import org.testng.annotations.AfterClass;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.DataProvider;
import org.testng.annotations.Test;

import static org.hamcrest.CoreMatchers.notNullValue;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.testng.Assert.assertTrue;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
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
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.commons.io.FileUtils;
import org.apache.commons.io.FilenameUtils;
import org.openqa.selenium.By;
import org.openqa.selenium.JavascriptExecutor;
import org.openqa.selenium.Keys;
import org.openqa.selenium.OutputType;
import org.openqa.selenium.TakesScreenshot;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.chrome.ChromeOptions;
import org.openqa.selenium.interactions.Actions;
import org.openqa.selenium.remote.DesiredCapabilities;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;

import com.rationaleemotions.pojo.ExecResults;
import com.rationaleemotions.pojo.SSHUser;
import com.rationaleemotions.ExecutionBuilder;
import com.rationaleemotions.SshKnowHow;

// based on: https://github.com/sergueik/selenium_tests/blob/master/src/test/java/com/github/sergueik/selenium/ParallelMultiBrowserTest.java
// based on https://github.com/tw1911/test1/blob/master/src/test/java/com/tw1911/test1/GoogleSearchTests.java
public class ExampleTest {

	private static String osName = getOSName();
	private static final boolean remote = true;
	private static final boolean headless = Boolean
			.parseBoolean(System.getenv("HEADLESS"));
	private static final String searchString = "Тестовое задание";

	// NOTE: cannot use primitive types as generic type arguments.
	private static ConcurrentHashMap<Long, WebDriver> drivers = new ConcurrentHashMap<Long, WebDriver>();

	private static Boolean debug = false;

	public int scriptTimeout = 5;
	public int flexibleWait = 30;
	public int implicitWait = 1;
	public int pollingInterval = 500;
	@SuppressWarnings("unused")
	private static long highlightInterval = 100;
	private static String browserExecutable;

	private static final Map<String, String> browserDrivers = new HashMap<>();
	static {
		browserDrivers.put("chrome",
				osName.equals("windows") ? "chromedriver.exe" : "chromedriver");
		browserDrivers.put("firefox",
				osName.equals("windows") ? "geckodriver.exe" : "geckodriver");
		browserDrivers.put("edge", "MicrosoftWebDriver.exe");
	}

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

	private static final Map<String, String> browserDriverSystemProperties = new HashMap<>();
	static {
		browserDriverSystemProperties.put("chrome", "webdriver.chrome.driver");
		browserDriverSystemProperties.put("firefox", "webdriver.gecko.driver");
		browserDriverSystemProperties.put("edge", "webdriver.edge.driver");
	}

	// to sensure thread safety
	// initialize driver, actions, js, screenshot and other common clases per-test
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

		driver.manage().timeouts().setScriptTimeout(scriptTimeout,
				TimeUnit.SECONDS);

		@SuppressWarnings("unused")
		Actions actions = new Actions(driver);

		@SuppressWarnings("unused")
		TakesScreenshot screenshot = ((TakesScreenshot) driver);
		@SuppressWarnings("unused")
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

		// take a screenshot
		File scrFile = ((TakesScreenshot) driver).getScreenshotAs(OutputType.FILE);
		String currentDir = System.getProperty("user.dir");
		// save the screenshot in png format on the disk.
		try {
			FileUtils.copyFile(scrFile,
					new File(FilenameUtils.concat(currentDir, "screenshot.png")));
		} catch (IOException e) {
		}

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

		@SuppressWarnings("unused")
		Actions actions = new Actions(driver);

		driver.manage().timeouts().setScriptTimeout(scriptTimeout,
				TimeUnit.SECONDS);

		@SuppressWarnings("unused")
		TakesScreenshot screenshot = ((TakesScreenshot) driver);
		@SuppressWarnings("unused")
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
	// Can inject only one of <ITestContext, XmlTest> into a AfterClass annotated
	// method
	public static void tearDown() {
		String browser = "chrome";
		// commented for testing of Vagrantbox chef recipe
		// killRemoteProcess(getBrowserExecutable(browser, true));
		// killRemoteProcess(getBrowserDriverExecutable(browser, true));
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

			if (osName.equals("windows")) {
				browserExecutable = "chrome.exe";
				if (System.getProperty("os.arch").contains("64")) {
					String[] paths = new String[] {
							"C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe",
							"C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe" };
					// check file existence
					for (String path : paths) {
						File exe = new File(path);
						System.err.println("Inspecting browser path: " + path);
						if (exe.exists()) {
							chromeOptions.setBinary(path);
						}
					}
				} else {
					chromeOptions.setBinary(
							"c:\\Program Files\\Google\\Chrome\\Application\\chrome.exe");
				}
			} else {
				browserExecutable = "google-chrome-stable";
			}
			// the remote browser was hard coded to be chrome
			// fixing this temporarily
			capabilities.setBrowserName(
					/* DesiredCapabilities.chrome().getBrowserName() */ DesiredCapabilities
							.firefox().getBrowserName());
			DriverWrapper.add(remote ? "remote" : "chrome", capabilities);
		} else if (browser.equals("firefox")) {
			browserExecutable = osName.equals("windows")
					? new File("c:/Program Files (x86)/Mozilla Firefox/firefox.exe")
							.getAbsolutePath()
					: "/usr/bin/firefox";
			System.setProperty("webdriver.firefox.bin", browserExecutable);
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

	// will be incorrect for development on Windows machine
	// and testing in Vagrant Virtual Box Linux machine
	public static String getBrowserExecutable(String browser, Boolean remote) {
		String browserExecutable = null;
		if (browser.equals("chrome")) {
			if (remote) {
				browserExecutable = "google-chrome-stable";
			} else {
				if (osName.equals("windows")) {
					browserExecutable = "chrome.exe";
				} else {
					browserExecutable = "google-chrome-stable";
				}
			}
		} else if (browser.equals("firefox")) {
			if (remote) {
				browserExecutable = "firefox";
			} else {
				browserExecutable = osName.equals("windows") ? "firefox.exe"
						: "firefox";
			}
		}

		return browserExecutable;
	}

	public static String getBrowserDriverExecutable(String browser,
			Boolean remote) {
		if (remote) {
			return browser.matches("chrome") ? "chromedriver" : "geckodriver";
		} else {
			return browserDrivers.get(browser);
		}
	}

	// origin: https://github.com/rationaleemotions/simplessh
	// NOTE: dispatches the actual work to
	// https://github.com/torquebox/jruby-maven-plugins/blob/master/ruby-tools/src/main/java/de/saumya/mojo/ruby/script/Script.java
	// that may not be the fast way of doing it
	public static void killRemoteProcess(String processName) {
		String identityFile = getPropertyEnv("IdentityFile",
				"C:/Vagrant/.vagrant/machines/default/virtualbox/private_key");
		String hostName = getPropertyEnv("HostName", "127.0.0.1");
		String sshFolder = identityFile.replaceAll("/[^/]+$", "");
		String user = getPropertyEnv("User", "vagrant");
		int port = Integer.parseInt(getPropertyEnv("Port", "2222"));
		String command = String.format("killall %s", processName.trim());
		SSHUser sshUser = new SSHUser.Builder().forUser(user)
				.withSshFolder(new File(sshFolder))
				.usingPrivateKey(new File(identityFile)).build();
		SshKnowHow ssh = new ExecutionBuilder().connectTo(hostName).onPort(port)
				.includeHostKeyChecks(false).usingUserInfo(sshUser).build();

		@SuppressWarnings("unused")
		ExecResults results = ssh.executeCommand(command);
		// TODO: process results
	}

	private static String propertiesFileName = "vagarant.properties";

	// https://github.com/TsvetomirSlavov/wdci/blob/master/code/src/main/java/com/seleniumsimplified/webdriver/manager/EnvironmentPropertyReader.java
	public static String getPropertyEnv(String name, String defaultValue) {
		Map<String, String> propertiesMap = getProperties(
				String.format("%s/src/test/resources/%s",
						System.getProperty("user.dir"), propertiesFileName));

		String value = propertiesMap.get(name);
		if (value == null) {
			System.getProperty(name);
			if (value == null) {
				value = System.getenv(name);
				if (value == null) {
					value = defaultValue;
				}
			}
		}
		return value;
	}

	public static Map<String, String> getProperties(final String fileName) {
		Properties p = new Properties();
		Map<String, String> propertiesMap = new HashMap<>();
		// System.err.println(String.format("Reading properties file: '%s'",
		// fileName));
		try {
			p.load(new FileInputStream(fileName));
			@SuppressWarnings("unchecked")
			Enumeration<String> e = (Enumeration<String>) p.propertyNames();
			for (; e.hasMoreElements();) {
				String key = e.nextElement();
				String val = p.get(key).toString();
				System.out.println(String.format("Reading: '%s' = '%s'", key, val));
				propertiesMap.put(key, resolveEnvVars(val));
			}

		} catch (FileNotFoundException e) {
			System.err.println(
					String.format("Properties file was not found: '%s'", fileName));
			e.printStackTrace();
		} catch (IOException e) {
			System.err.println(
					String.format("Properties file is not readable: '%s'", fileName));
			e.printStackTrace();
		}
		return (propertiesMap);
	}

	public static String resolveEnvVars(String input) {
		if (null == input) {
			return null;
		}
		Pattern p = Pattern.compile("\\$(?:\\{(\\w+)\\}|(\\w+))");
		Matcher m = p.matcher(input);
		StringBuffer sb = new StringBuffer();
		while (m.find()) {
			String envVarName = null == m.group(1) ? m.group(2) : m.group(1);
			String envVarValue = System.getenv(envVarName);
			m.appendReplacement(sb,
					null == envVarValue ? "" : envVarValue.replace("\\", "\\\\"));
		}
		m.appendTail(sb);
		return sb.toString();
	}
}
