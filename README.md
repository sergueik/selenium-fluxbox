### Info


This project offers a standalone Ubuntu Trusty __14.04__ __LTS__ and Xenial __16.04__ Vagrant box instances containing

 * [Fluxbox](https://wiki.debian.org/FluxBox)
 * [Tmux](https://github.com/tmux/tmux) autologin
 * Stable release of Selenium Server 3.x or legacy __2.53__ or other, user-specified version of Selenium
 * Chrome and Chrome Driver
 * Firefox with optional [Gecko Driver](https://github.com/mozilla/geckodriver/releases)

The 'bleeding edge' versions of the drivers do not always work well together, e.g. through errors like:
`org.openqa.selenium.WebDriverException: unknown error: Chrome version must be >= 52.0.2743.0 ...`
Likewise the Selenium hub error
![box](https://github.com/sergueik/selenium-fluxbox/blob/master/screenshots/session_error.png)
indicates a likely versions mismatch between Selenium, Geckodriver and Firefox, or Selenium, ChromeDriver and Chrome.

This has been especially true with early Selenium __3.x__ releases.
One often wishes to enforce specific past versions of Selenium-based toolchain.
Vagrant makes this easy.
![box](https://github.com/sergueik/selenium-fluxbox/blob/master/screenshots/box.png)

Note: Docker makes this easy too, but there is no native Docker port for Windows 8.x and earlier and this could be one's reason to stay with Vagrant

This project `Vagrantfile` is developed based on [Anomen/vagrant-selenium](https://github.com/Anomen/vagrant-selenium/blob/master/script.sh)
The `Vagrantfile.xenial` for Ubuntu Xenial __16.04__ __LTS__
was recently added - use at own risk.

### Usage

Download the vagrant box images of Trusty [trusty-server-amd64-vagrant-selenium.box](https://atlas.hashicorp.com/ubuntu/boxes/trusty64)
 or Xenial [vagrant-selenium](https://app.vagrantup.com/Th33x1l3/boxes/vagrant-selenium/versions/0.2.1/providers/virtualbox.box)
locally, name it `trusty-server-amd64-vagrant-selenium.box` / `xenial-server-amd64-vagrant-selenium.box` and place inside the `~/Downloads` or `$env:USERPROFILE\Downloads`.

Then run
```bash
export PROVISION_SELENIUM=true
vagrant up
```
Specific versions of Selenium Server, Firefox, Gecko Driver, Chrome, Chrome Driver can be set through the environment variables
`SELENIUM_VERSION`, `FIREFOX_VERSION`, `GECKODRIVER_VERSION`, `CHROME_VERSION`, `CHROMEDRIVER_VERSION`.

Sampe supported combinations of legacy browser and driver versions are listed below.
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

For Chrome, the `CHROME_VERSION` can also set to `stable`, `unstable` or `beta` - forcing the `.deb` package of selected build of Chrome browser to be installed from the
[google repository](https://www.google.com/linuxrepositories/).

`Vagrantfile` automates the Chrome debian package download from
[https://www.slimjet.com/chrome/google-chrome-old-version.php](https://www.slimjet.com/chrome/google-chrome-old-version.php).
Check if desired version is available. There is also were few relatively recent 32-bit Chrome builds there.
Note there is often few Chrome builds released with the same major, minor version like e.g. __69.0.3497.100__ vs. __69.0.3497.92__ and on
slimjet one typically finds just one of those - therefore it is not recommended to use Slimjet with the most recent builds.

Internaly the chromedriver communicates with Chrome browser via [WebSockets DevTools debugging interface](https://stackoverflow.com/questions/44244505/how-chromedriver-is-communicating-internally-with-the-browser?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa).

Note that the actual download directory `http://www.slimjetbrowser.com/chrome/lnx/` is not directly browsable.
Alternatively a handful of *really* old Chrome browser debian packages can be  manually downloaded from [https://google-chrome.en.uptodown.com/ubuntu/old](https://google-chrome.en.uptodown.com/ubuntu/old).

Note: the runtime error `Unsupported major.minor version 52.0` is a manifestation of a Java version mismatch between the Selenium.jar and the environment.
For Ubuntu Trusty, one can switch to JDK 8 by setting the `USE_ORACLE_JAVA` environment to `true` and re-provision the box.

### Limitations
  * The hub is available on `http://127.0.0.1:4444/wd/hub/static/resource/hub.html` with some delay after the Virtual Box reboot - currently there is no visual cue on when the box is ready.

  * If the screen resolution is too low, run the following command on the host
```bash
vboxmanage controlvm "Selenium Fluxbox" setvideomodehint 1280 900 32
```
this currently works with trusty but not always with xenial base box in Virtual Box.

### Work in Progress
 * Probe [http://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/](http://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/) and /or [https://google-chrome.en.uptodown.com/ubuntu/old](https://google-chrome.en.uptodown.com/ubuntu/old) for a valid past Chrome build is a
 * Enable [gecko driver](https://developer.mozilla.org/en-US/docs/Mozilla/QA/Marionette/WebDriver)
 * Dockerfile - see e.g. [docker](https://github.com/elgalu/docker-selenium), [docker-selenium-firefox-chrome-beta](https://github.com/vvo/docker-selenium-firefox-chrome-beta), [lucidworks/browser-tester](https://github.com/lucidworks/browser-tester)
 * Support downloads from [chromium dev channel](http://www.chromium.org/getting-involved/dev-channel). More about using headless Chrome see
   [Getting Started with Headless Chrome](https://developers.google.com/web/updates/2017/04/headless-chrome) and [](https://chromium.googlesource.com/chromium/src/+/lkgr/headless/README.md).
 * [xvfb customizations, video recording](https://github.com/aimmac23/selenium-video-node)

### See also:

 * [Google Chrome Old Versions - for Windows only](https://google_chrome.en.downloadastro.com/old_versions/)
 * [Selected old versions](https://google-chrome.en.uptodown.com/ubuntu/old)
 * [Chromium old builds for Ubuntu](https://www.ubuntuupdates.org/pm/google-chrome-stable)
 * [bonigarcia/webdrivermanager](https://github.com/bonigarcia/webdrivermanager) - this project allows the Java test suite to control (to a certain extent) the verson of the browserdriver for a selection of browsers.
 * [how to disable Chrome Browser auto update](https://stackoverflow.com/questions/18483087/how-to-disable-google-chrome-auto-update)
 * [xvfb headless selenium box blog](https://altarmoss.wordpress.com/2017/05/22/how-to-create-a-headless-selenium-server-vagrant-box/)

 ### Author
[Serguei Kouzmine](kouzmine_serguei@yahoo.com)
