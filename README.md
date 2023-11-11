### Info

This project offers a standalone Ubuntu Vagrant box instance containing

 * [Fluxbox](https://wiki.debian.org/FluxBox)
 * [tmux](https://github.com/tmux/tmux) autologin
 * Pinned User-specified version of Selenium ( __4.*__, __3.x__ or legacy __2.53__ )
 * Chrome with Chrome Driver
 * Firefox with Gecko Driver
 * Katalon IDE (experimental)

It is not uncommon that the 'bleeding edge' versions of the drivers don't work well together, e.g. throwing errors like:
`org.openqa.selenium.WebDriverException: unknown error: Chrome version must be >= 52.0.2743.0 ...` (this has been observed quie often during early Selenium __3.x__, and then again with __4.0.alpha__ releases).
Likewise the Selenium hub error on the screenshot
![box](https://github.com/sergueik/selenium-fluxbox/blob/master/screenshots/session_error.png)

illustrates a likely versions mismatch between Selenium, Geckodriver and Firefox, or Selenium, ChromeDriver and Chrome.


One often wishes to enforce specific past versions of Selenium-based toolchain.
Vagrant makes this easy.
![box](https://github.com/sergueik/selenium-fluxbox/blob/master/screenshots/box.png)

Note: Docker makes this easy too, but there is no native Docker port for Windows 8.x and earlier and
this could be one's reason to stay with Vagrant.
  
This project contains __Trusty___ __14.04__ __LTS__ `Vagrantfile` that is loosely based on [anomen/vagrant-selenium](https://github.com/Anomen/vagrant-selenium/blob/master/script.sh)
There is also an  Ubuntu __Xenial__ __16.04__  __LTS__ `Vagrantfile.xenial`: there are differences in openjdk/Oracle JDK release-specific repo availability between  __Xenial__ and __Trusty__. 
Support of Ubuntu __Bionic__ __18.04__ and __Focal__ __20.04__ releases is planned - no strong depenency between the browser and OS release exits for Linux.

### Usage

Download the vagrant box images of
Trusty [trusty-server-amd64-vagrant-selenium.box](https://atlas.hashicorp.com/ubuntu/boxes/trusty64)
 or Xenial [vagrant-selenium](https://app.vagrantup.com/Th33x1l3/boxes/vagrant-selenium/versions/0.2.1/providers/virtualbox.box)
locally, name it `trusty-server-amd64-vagrant-selenium.box` and
`xenial-server-amd64-vagrant-selenium.box` respectively and store in the `Downloads` directory of the user.

Then run
```bash
export PROVISION_SELENIUM=true
vagrant up
```
or on Windows
```cmd
set PROVISION_SELENIUM=true
vagrant up
```

For downloading box for the very first time into `Downloads` directory add the following setting (note: this setting is experimental):
```
export BOX_DOWNLOAD=true
export PROVISION_SELENIUM=true
vagrant up
```
Specific versions of Selenium Server, Firefox, Gecko Driver, Chrome, Chrome Driver can be set through the environment variables
`SELENIUM_VERSION`, `FIREFOX_VERSION`, `GECKODRIVER_VERSION`, `CHROME_VERSION`, `CHROMEDRIVER_VERSION`.

if a specific version of the Selenium Jar or browser is needed, set it via

```sh
export SELENIUM_VERSION=3.141.59
export CHROME_VERSION=75.0.3770.80
export FIREFOX_VERSION=45.0.1
```
or

```cmd
set SELENIUM_VERSION=3.5.3
set SELENIUM_VERSION=3.141.59
set CHROME_VERSION=75.0.3770.80
```

Also the `USE_ORACLE_JAVA` setting is recognized to use oracle JDK on Trusty.

```bash
export PROVISION_SELENIUM=true
export SELENIUM_VERSION=3.14.0
export USE_ORACLE_JAVA=true
export CHOME_VERSION=48.0.2564.109
export CHROMEDRIVER_VERSION=2.30
vagrant up
```

For the list or recognized chrome versions, inspect the `Vagrantfile`.  Another option to lookup the available choices of Chrome browser specific release e.g. __48__, is to run
```sh
ruby get_chrome_versions.rb -r 48
```
this will print:
```Ruby
["48.0.2564.109",
 "http://www.slimjetbrowser.com/chrome/lnx/chrome64_48.0.2564.109.deb"]
```
therefore one must set the `CHROMEDRIVER_VERSION` to `48.0.2564.109` if a release 48 is intended.

Few supported combinations of legacy browser and driver versions are listed below.
Note: this list is provided as an example, and is not maintained.

|                      |              |
|----------------------|--------------|
| SELENIUM_VERSION     | 3.2.0        |
| FIREFOX_VERSION      | 54.0b13      |
| GECKODRIVER_VERSION  | 0.17.0       |
| CHROME_VERSION       | 59.0.3071.86 |
| CHROMEDRIVER_VERSION | 2.30         |

|                      |              |
|----------------------|--------------|
| SELENIUM_VERSION     | 2.53         |
| FIREFOX_VERSION      | 45.0.1       |
| CHROME_VERSION       | 54.0.2840.71 |
| CHROMEDRIVER_VERSION | 2.24         |

|                      |              |
|----------------------|--------------|
| SELENIUM_VERSION     | 2.47         |
| FIREFOX_VERSION      | 40.0.3       |
| CHROME_VERSION       | 50.0.2661.75 |
| CHROMEDRIVER_VERSION | 2.16         |

With Chrome, `stable`, `unstable` or `beta` are valid versions, appropriate `.deb` package from the
[google repository](https://www.google.com/linuxrepositories/) will be installed.

The `Vagrantfile` automates the download  of specific old build of from
[https://www.slimjet.com/chrome/google-chrome-old-version.php](https://www.slimjet.com/chrome/google-chrome-old-version.php). Note, there are no old Chrome builds __87.x__, __88.x__, or __89.x__ and __91__through __101__ there 
Check if desired version is available. There is also were few relatively recent 32-bit Chrome builds there.
Note the Chrome browser is often re-released over time with the same major and minor version like
e.g. __69.0.3497.100__ vs. __69.0.3497.92__
builds __72.0.3626.68__  vs. __72.0.3626.96__ vs. __72.0.3626.109__ vs. __72.0.3626.119__ and so on,
with major version number bumps relatively unfrequent.
The build one can find on slimjet is not always the very latest one of those -
therefore it is not recommended to use Slimjet with the very recent past builds.

Internaly the chromedriver communicates with Chrome browser via [WebSockets DevTools debugging interface](https://stackoverflow.com/questions/44244505/how-chromedriver-is-communicating-internally-with-the-browser?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa).

Note that the actual download directory `http://www.slimjetbrowser.com/chrome/lnx/` is not directly browsable.
Alternatively a handful of *really* old Chrome browser debian packages can be  manually downloaded from [https://google-chrome.en.uptodown.com/ubuntu/old](https://google-chrome.en.uptodown.com/ubuntu/old).

Note: the runtime error `Unsupported major.minor version 52.0` is a manifestation of a Java version mismatch between the Selenium.jar and the environment.
For Ubuntu Trusty, one can switch to JDK 8 by setting the `USE_ORACLE_JAVA` environment to `true` and re-provision the box.

### Limitations
  * The hub is available on `http://127.0.0.1:4444/wd/hub/static/resource/hub.html` with some delay after the Virtual Box reboot - currently there is no visual cue on when the box is ready.

  * If the screen size is too low, run the following command on the host
```bash
vboxmanage controlvm "Selenium Fluxbox" setvideomodehint 1280 900 32
```
this currently works with trusty but not always with xenial base box in Virtual Box.

### Note Latest old Chrome builds

The Chrome Build 70 had multiple releases:
  - `70.0.3538.110`
  - `70.0.3538.102`
  - `70.0.3538.77`
  - `70.0.3538.67`

Not every build is available in slimjet.

###  Usage with Java projects
A minimal example Java TestNG parallel run Selenium test project is provided in the `example` direcrory:

![box](https://github.com/sergueik/selenium-fluxbox/blob/master/screenshots/parallel-run-capture.png)

It will further benefit from inegrating with [vagrant-maven-plugin](https://github.com/nicoulaj/vagrant-maven-plugin)
plugin and [simple-ssh](https://github.com/RationaleEmotions/SimpleSSH) jar e.g. to manage browsers and browser
drivers in the Virtualbox after the test completion
thru ssh using Vagrant-generated keys - this is work in progress.

one can find the key file location from Vagrant by running the command

```cmd
C:\HashiCorp\Vagrant\bin\vagrant.exe ssh-config
```
It would print something like
```sh
Host default
  HostName 127.0.0.1
  User vagrant
  Port 2222
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
	
  IdentitiesOnly yes
  LogLevel FATAL	
```
but only if the Virtual Box VM was launched by vagrant, it will refuse to give this information e.g.
if VM was launched through Virtual Box UI directly.


### Latest Chrome for Testing

To automatically download the stable chromedriver for Chrome testing from [Chrome for Testing availability](https://googlechromelabs.github.io/chrome-for-testing/) page

![chrome-for-testing](https://github.com/sergueik/selenium-fluxbox/blob/master/screenshots/capture-chrome-for-testing.png)

one can use this command (currntly it is quite long):

```sh
xmllint --htmlout --html --xpath "//section[@id='stable']/div[@class='table-wrapper']/table/tbody/tr/th[code='chromedriver']/../th[code = 'linux64']/../td[code='200']/../td[1]/code/text()" chrome-for-testing.html 2>/dev/null
```

this will print:
```text
https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/119.0.6045.105/linux64/chromedriver-linux64.zip
```

* NOTE: the "and" in the condition also appears to work:

```sh

xmllint --htmlout --html --xpath "//section[@id='stable']/div[@class='table-wrapper']/table/tbody/tr[th/code='chromedriver' and td/code='200' and th/code='linux64']/td[1]/code/text()" chrome-for-testing.html 2>/dev/null
```
```text
https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/119.0.6045.105/linux64/chromedriver-linux64.zip
```
and so is the following two step extraction:
```sh
xmllint --htmlout --html --xpath "//div[@class='table-wrapper summary']/table/tbody/tr[th/a/text()='Stable']/td[1]/code/text()" chrome-for-testing.html 2>/dev/null

```
```text
119.0.6045.105
```
```sh

xmllint --htmlout --html --xpath "//code[contains(text(),'/119.0.6045.105/') and contains(text(),'chromedriver-linux64')]/text()" chrome-for-testing.html 2>/dev/null
```
```text
https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/119.0.6045.105/linux64/chromedriver-linux64.zip
```
### Work in Progress

  * Probe [http://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/](http://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/) and /or [https://google-chrome.en.uptodown.com/ubuntu/old](https://google-chrome.en.uptodown.com/ubuntu/old) for a valid past Chrome build is a
  * Enable [gecko driver](https://developer.mozilla.org/en-US/docs/Mozilla/QA/Marionette/WebDriver)
  * Dockerfile - see e.g. [docker](https://github.com/elgalu/docker-selenium), [docker-selenium-firefox-chrome-beta](https://github.com/vvo/docker-selenium-firefox-chrome-beta), [lucidworks/browser-tester](https://github.com/lucidworks/browser-tester), [Docker image based on Ununtu with JDK and maven for Java](https://github.com/markhobson/docker-maven-chrome)
  * Support downloads from [chromium dev channel](http://www.chromium.org/getting-involved/dev-channel). More about using headless Chrome see
  * [Getting Started with Headless Chrome](https://developers.google.com/web/updates/2017/04/headless-chrome) and [](https://chromium.googlesource.com/chromium/src/+/lkgr/headless/README.md).
  * [xvfb customizations, video recording](https://github.com/aimmac23/selenium-video-node)
  * desktop shortcut generation e.g. [example](https://github.com/regaur/puppeteer/blob/master/puppeteer.install) for ArchLinux, chromium puppeteer
  * [ruby gem for authoring and managing tmux sessions easily](https://github.com/tmuxinator/tmuxinator)
  * [constructing expression for XPath with multiple conditions in xmllint](https://stackoverflow.com/questions/10247978/xpath-with-multiple-conditions)
### See also:

  * [Google Chrome Old Versions - for Windows only](https://google_chrome.en.downloadastro.com/old_versions/)
  * [Selected old versions](https://google-chrome.en.uptodown.com/ubuntu/old)
  * [chromium old builds for Ubuntu](https://www.ubuntuupdates.org/pm/google-chrome-stable)
  * [table](http://chromedriver.chromium.org/downloads) of matching Chromedriver and Chrome browser versions
  * [bonigarcia/webdrivermanager](https://github.com/bonigarcia/webdrivermanager) allows the Java test suite to specify the browser driver verson for all standard browsers.
  * [abhishek8908/selenium-drivers-download-plugin](https://github.com/abhishek8908/selenium-drivers-download-plugin) maven plugin which downloads specific versions of chromedriver, iedriverServer, edge or geckodriver by executing a specific custom goal `generateDrivers` during maven life cycle.
  * [how to disable Chrome Browser auto update](https://stackoverflow.com/questions/18483087/how-to-disable-google-chrome-auto-update)
  * [xvfb headless selenium box blog](https://altarmoss.wordpress.com/2017/05/22/how-to-create-a-headless-selenium-server-vagrant-box/)
  * [examples and documentation](https://www.codota.com/code/java/classes/de.saumya.mojo.ruby.script.ScriptFactory)
  * [parallel testing testng framerowk](https://github.com/CybertekSchool/parallel-multi-browser-testng-framework) - note utility code redundant across various projects of that author.
  * [the Chromium Projects](https://www.chromium.org/getting-involved/download-chromium)
  * Chromium [Puppeteer](https://github.com/GoogleChrome/puppeteer) - headless [Dockerfile](https://github.com/landaida/puppeteer/blob/master/Dockerfile) for Debian-based box.
  * [Puppeteer](https://github.com/GoogleChrome/puppeteer) visual [recorder](https://github.com/euprogramador/puppeteer-screen-recorder) with Xvfb, standalone
  * [Puppeteer](https://github.com/GoogleChrome/puppeteer) example [tests](https://github.com/checkly/puppeteer-examples)
  * Puppeteer web scraping [tutorial](https://github.com/emadehsan/thal)
  * [sdkman](https://sdkman.io/) - parallel version manager (in particular, of JDK).
  * [oracle logins](http://bugmenot.com/view/oracle.com) for downloading Java SE 8 and earlier from oracle technet [Java Archive Downloads](https://www.oracle.com/technetwork/java/javase/downloads/java-archive-javase8-2177648.html) page.
  *  shell script to [install chrome latest RPM](https://intoli.com/install-google-chrome.sh) via `curl $URL | bash - ` from JDK11 + chrome [Dockerfile](https://hub.docker.com/r/bigtincan/jdk11-chrome/dockerfile)
  * [xserver-xorg-video-dummy driver](https://techoverflow.net/2019/02/23/how-to-run-x-server-using-xserver-xorg-video-dummy-driver-on-ubuntu/)
  * an old instruction for headless debian [setup](http://cosmolinux.no-ip.org/raconetlinux2/dummy_radeon_nvidia.html) (via dumy X driver)
  * chromium snapshots release directories
     + [windows](https://commondatastorage.googleapis.com/chromium-browser-snapshots/index.html?prefix=Win/)
     + [linux](https://commondatastorage.googleapis.com/chromium-browser-snapshots/index.html?prefix=Linux_x64/)

### License
This project is licensed under the terms of the MIT license.

### Author
[Serguei Kouzmine](kouzmine_serguei@yahoo.com)
