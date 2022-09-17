# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'fileutils'
require 'find'
require 'json'
require 'net/http'
# http gem that has to be compiled
# require 'http'
require 'pathname'
require 'pp'

provision_selenium = ENV.fetch('PROVISION_SELENIUM', '')

# This verison of Vagrantfile removes various "alternative" commands many of which do not work
# Please refer to Vagrantfile.OLD for those command details.

selenium_version = ENV.fetch('SELENIUM_VERSION', '3.14.0')
chromedriver_version = ENV.fetch('CHROMEDRIVER_VERSION', '')
firefox_version = ENV.fetch('FIREFOX_VERSION', '')
geckodriver_version = ENV.fetch('GECKODRIVER_VERSION', '')

use_oracle_java = ENV.fetch('USE_ORACLE_JAVA', '')

# experimental: install Katalon Studio for Linux
# NOTE: Katalon Studio requires that OpenJDK 8 - not the Oracle JDK - is installed
provision_katalon = ENV.fetch('PROVISION_KATALON', '') # empty for false
# NOTE: not needed for this specific base box.
provision_yandex = ENV.fetch('PROVISION_YANDEX', '') # empty for false
# NOTE: not needed for this specific base box.
provision_vnc = ENV.fetch('PROVISION_VNC', '') # empty for false
# Automatically download box into ~/Downloads. useful to upgrade base box
# NOTE: the strongly-typed ENV.fetch does not work correctly
# $export BOX_DOWNLOAD=false
# box_download = ENV.fetch('BOX_DOWNLOAD', false)
# puts '!' if box_download
# will print the '!'
box_download = ENV.fetch('BOX_DOWNLOAD', false)
debug = ENV.fetch('DEBUG', false)
have_ssh_key = ENV.fetch('HAVE_SSH_KEY', false)

# Examine that specific Chrome version is available on https://www.slimjet.com/chrome/google-chrome-old-version.php
# TODO: embed the 'get_chrome_version.rb'
available_chrome_versions = %w|
  104.0.5112.102
  103.0.5060.53
  102.0.5005.63
  90.0.4430.72
  86.0.4240.75
  84.0.4147.135
  83.0.4103.116
  81.0.4044.92
  80.0.3987.149
  79.0.3945.88
  78.0.3904.97
  76.0.3809.100
  75.0.3770.80
  71.0.3578.80
  70.0.3538.77
  69.0.3497.92
  68.0.3440.84
  67.0.3396.79
  66.0.3359.181
  65.0.3325.181
  64.0.3282.140
  63.0.3239.108
  62.0.3202.75
  61.0.3163.79
  60.0.3112.90
  59.0.3071.86
  58.0.3029.96
  57.0.2987.133
  56.0.2924.87
  55.0.2883.75
  54.0.2840.71
  53.0.2785.116
  52.0.2743.116
  51.0.2704.84
  50.0.2661.75
  49.0.2623.75
  48.0.2564.109
|
# TODO: add mnemonicts as oldest => -1, newest => 0
chrome_version = ENV.fetch('CHROME_VERSION', available_chrome_versions[0])

unless chrome_version.empty? or chrome_version =~ /(?:beta|stable|dev|unstable)/ or available_chrome_versions.include?(chrome_version)
  puts 'CHROME_VERSION should be set to "stable", "unstable" "dev" or "beta"'
  puts "Specific old Chrome versions available from https://www.slimjet.com/chrome/google-chrome-old-version.php\n" + available_chrome_versions.join("\n")
  exit
end

VAGRANTFILE_API_VERSION = '2'
basedir = ENV.fetch('HOME','') || ENV.fetch('USERPROFILE', '')
box_memory = ENV.fetch('BOX_MEMORY', '2048').to_i
basedir = basedir.gsub('\\', '/')
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  if have_ssh_key
    # https://www.vagrantup.com/docs/vagrantfile/ssh_settings.html
    # see also
    # https://riselab.ru/ustanovka-i-nastrojka-rabochej-sredy-homestead-dlya-laravel/
    config.ssh.insert_key = false
  end
  config.vm.box = 'ubuntu/trusty64-fluxbox'
  # gets cached in ~/.vagrant.d/boxes/ubuntu-VAGRANTSLASH-trusty64-fluxbox/0/virtualbox
  # see also http://www.vagrantbox.es/ and http://dev.modern.ie/tools/vms/linux/
  config_vm_box_name = 'trusty-server-amd64-vagrant-selenium.box'
  config.vm.box_url = "file://#{basedir}/Downloads/#{config_vm_box_name}"
  # Localy cached vagrant box image
  version = '14.04'
  version = '20190206.0.0'
  # NOTE: the https://superuser.com/questions/747699/vagrant-box-url-for-json-metadata-file - the metadata.json should be loaded as directory index, not explicitly
  if box_download == true
    # based on: https://docs.ruby-lang.org/en/2.0.0/Net/HTTP.html#class-Net::HTTP-label-Setting+Headers
    # https://www.vagrantup.com/docs/vagrant-cloud/api.html
    uri = URI('https://vagrantcloud.com/ubuntu/boxes/trusty64/versions')
    req = Net::HTTP::Post.new(uri)
    req.set_form_data('from' => '') # none needed ?
    req.content_type = 'application/json'
    begin
      res = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req)
	# TODO: end of file reached
      end
      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        # OK
        metadata_obj = JSON.parse(response.body)
      else
       res.value
      end
    rescue => e
      puts 'Exception (ignored) '+ e.to_s
    end
    # TODO: use http gem
    # api = HTTP.persistent('https://vagrantcloud.com').headers( 'Content-Type' => 'application/json')
    # metadata_response = api.post '/ubuntu/boxes/trusty64/versions'
    # metadata_obj = JSON.parse(metadata_response.body)
    # NOTE: curl --head -k $URL
    # does not always show the size (Content-Length header) of the box file.
    # e.g. Vagrantcloud does not.
    box_download_url = "https://vagrantcloud.com/ubuntu/boxes/trusty64/versions/#{version}/providers/virtualbox.box"
    box_filepath = config.vm.box_url.gsub(Regexp.new('^file://'),'')
    if File.exist?(box_filepath)
      $stderr.puts (box_filepath + ' already downloaded. Remove the file to re-download')
    else  status = true
      $stderr.puts "Downloading from #{box_download_url} to #{box_filepath}"
      %x|curl -k -L #{box_download_url} -o #{box_filepath}|
    end
  end
  config.vm.network :forwarded_port, guest:4444, host:4444
  config.vm.network :private_network, ip: '192.168.33.10'
  config.vm.boot_timeout = 600
  # Configure common synced folder
  config.vm.synced_folder './' , '/vagrant'
  config.vm.provision 'shell', inline: <<-END_OF_PROVISION
#!/bin/bash
DEBUG='#{debug}'
if [[ ! -z $DEBUG ]] ; then
set -x
fi

#=========================================================
echo 'Install the packages'

# GPG servers aren't entirely reliable

declare -A key_hash=( ['keyserver.ubuntu.com']='1397BC53640DB551' ['keyserver.ubuntu.com']='6494C6D6997C215E' ['pgp.mit.edu']='6494C6D6997C215E')
for server in "${!key_hash[@]}"; do sudo apt-key adv --keyserver "${server}" --recv-keys "${key_hash[$server]}"; done

apt-get -qq update
apt-get -qqy install fluxbox xorg xserver-xorg-video-dummy xvfb unzip vim default-jre rungetty wget libxml2-utils jq
#=========================================================
USE_ORACLE_JAVA='#{use_oracle_java}'
if  [ ! -z "${USE_ORACLE_JAVA}" ] ; then
  echo 'Installing the oracle 8 JDK from ppa:webupd8team/java'
  # does it still stops on Oracle Licence Agreement prompt
  # for alternative install set USE_ORACLE_JAVA
  add-apt-repository ppa:webupd8team/java -y
  apt-get -qq update
  # origin: https://examples.javacodegeeks.com/devops/docker/docker-compose-example/
  echo 'oracle-java8-installer shared/accepted-oracle-license-v1-1 boolean true' | debconf-set-selections
  apt-get -qqy install oracle-java8-installer
  apt-get -qqy install oracle-java8-set-default
else
  add-apt-repository -y ppa:openjdk-r/ppa
  apt-get -qqy update
  apt-get install -qqy openjdk-8-jdk
  update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java
fi
#=========================================================
echo Set autologin for the Vagrant user
sed -i '$ d' /etc/init/tty1.conf
echo 'exec /sbin/rungetty --autologin vagrant tty1' >> /etc/init/tty1.conf
#=========================================================
cat <<EOF>> .profile
if [ ! -e '/tmp/.X0-lock' ] ; then
  echo -n Start X on login
  startx
else
  echo X is alredy running..
fi
EOF
#=========================================================
PROVISION_SELENIUM='#{provision_selenium}'
if [[ $PROVISION_SELENIUM ]] ; then
  echo Updating Selenium app stack
  FIREFOX_VERSION='#{firefox_version}'
  if [[ $FIREFOX_VERSION ]] ; then
    echo Install Firefox version ${FIREFOX_VERSION}
    cd /vagrant
    PACKAGE_ARCHIVE="firefox-${FIREFOX_VERSION}.tar.bz2"
    if [ ! -e $PACKAGE_ARCHIVE ] ; then
      URL="https://ftp.mozilla.org/pub/firefox/releases/${FIREFOX_VERSION}/linux-x86_64/en-US/${PACKAGE_ARCHIVE}"
      wget -O $PACKAGE_ARCHIVE -nv $URL
    else
      echo Using already downloaded archive $PACKAGE_ARCHIVE
    fi
    mkdir -p /home/vagrant/firefox
    cd /home/vagrant
    tar xjf "/vagrant/${PACKAGE_ARCHIVE}"
    cp -R firefox /usr/lib
  else
    echo Install the latest Firefox
    apt-get -qqy install firefox
  fi
  #=========================================================
  SELENIUM_VERSION='#{selenium_version}'
  SELENIM_RELEASE_URL='https://selenium-release.storage.googleapis.com/'
  if [[ $SELENIUM_VERSION ]] ; then
    echo Download specific Selenium version $SELENIUM_VERSION
    SELENIUM_RELEASE=$(curl -s $SELENIM_RELEASE_URL | xmllint --xpath "//*[name() = 'Key'][contains(text(), 'selenium-server-standalone')][contains(text(), '${SELENIUM_VERSION}.jar')]/text()" - )
    if [ -z $SELENIUM_RELEASE ] ; then
      echo "Invalid version: ${SELENIUM_VERSION}"
      exit 1
    else
      echo "Selenium release: ${SELENIUM_RELEASE}"
    fi
  else
    echo Determine the latest Selenium Server version to download
    # use sort field, tab options to build the equivalent of $VERSION_MAJOR*10000 + $VERSION_MINOR *10 + $VERSION_BUILD
    SELENIUM_VERSION=$(curl -s $SELENIM_RELEASE_URL | xmllint --xpath "//*[local-name() = 'Key'][contains(text(), 'selenium-server-standalone')][contains(text(), '.jar')]" --shell - | sed -ne 's/<\\/*Key>/\\n/pg' | awk -F / '{print $1}' | sort -r -u -n -k1,1 -k2,2 -k3,3 -t. | head -1 )
    echo "The latest Selenium Server version is ${SELENIUM_VERSION}"
  fi
  SELENIUM_RELEASE=$(curl -s $SELENIM_RELEASE_URL | xmllint --xpath "//*[name() = 'Key'][contains(text(), 'selenium-server-standalone')][contains(text(), '${SELENIUM_VERSION}.jar')]/text()" - )
  # SELENIUM_RELEASE=$(curl -s $SELENIM_RELEASE_URL | sed -n "s/.*<Key>\\(${SELENIUM_VERSION}\\/selenium-server-standalone[^<][^>]*\\)<\\/Key>.*/\\1/p")
  PACKAGE_ARCHIVE="selenium-server-standalone-${SELENIUM_VERSION}.jar"
  cd /vagrant
  if [[ ! -e $PACKAGE_ARCHIVE ]] ; then
    URL="https://selenium-release.storage.googleapis.com/${SELENIUM_RELEASE}"
    echo Downloading Selenium $PACKAGE_ARCHIVE from $URL
    wget -O $PACKAGE_ARCHIVE -nv $URL
    # TODO: retry if selenium-server-standalone-${SELENIUM_VERSION}.jar is truncated (rare)

  else
    echo Using already downloaded $PACKAGE_ARCHIVE
  fi
  cp $PACKAGE_ARCHIVE /home/vagrant/selenium-server-standalone.jar
  cd /home/vagrant
  chown vagrant:vagrant selenium-server-standalone.jar
  #=========================================================
  CHROME_VERSION='#{chrome_version}'
  if [[ $CHROME_VERSION ]] ; then
    echo installing libnss3
    # https://stackoverflow.com/questions/46126902/fix-nss-version-not-match-when-update-chrome-in-ubuntu
    # for trusty need the following command may get the correct version of libnss3, which is a prerequisite of Chrome 64+
    apt-get -qqy install --only-upgrade libnss3
    echo "installing Chrome $CHROME_VERSION"
    case $CHROME_VERSION in
      beta|stable|unstable)
        # the https://dl.google.com/linux/chrome/deb occasionally returns a 404 and this will fail without discovering it
        # and the only way to install stable Chrome is to interactiely download it
        # https://www.google.com/linuxrepositories/
        # http://www.allaboutlinux.eu/install-google-chrome-in-debian-8/
        wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
        # may need a second time for some reason sporadic error
        # GPG error: http://dl.google.com stable Release: The following signatures couldn't be verified because the public key is not available: NO_PUBKEY 1397BC53640DB551
        apt-add-repository http://dl.google.com/linux/chrome/deb/
        apt-get -qq update
        apt-get install -qy --allow-unauthenticated google-chrome-${CHROME_VERSION}
      ;;
      *)
        wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
        apt-get remove -qqy -f google-chrome-stable
        apt-get -qqy install libxml2-utils
        curl -s https://www.slimjet.com/chrome/google-chrome-old-version.php -o /tmp/a.html
        echo 'Trying the new release format'
        LATEST_CHROME_VERSION=$(xmllint --htmlout --html --xpath "//table[3]//tr/td/a[contains(@href,'file=files')]/@href" /tmp/a.html 2> /dev/null | sed 's|href="download-chrome.php?file=files%2F\\([0-9][0-9.]*\\)%2Fgoogle-chrome-stable_current_amd64.deb"|\\n\\1|gp;'| sort -r -u -n -k1,1 -k2,2 -k3,3 -t.| head -1 | awk '{print $1}')
        LATEST_CHROME_RELEASE="files/${LATEST_CHROME_VERSION}/google-chrome-stable_current_amd64.deb"
        PACKAGE_ARCHIVE="google-chrome-stable_current_amd64.deb"
        if [ -z $LATEST_CHROME_VERSION ] ;then
        echo 'Trying the old release format'
          LATEST_CHROME_VERSION=$(xmllint --htmlout --html --xpath "//table[3]//tr/td/a[contains(@href,'file=lnx')]/@href" /tmp/a.html 2> /dev/null | sed 's|href="download-chrome.php?file=lnx%2Fchrome64_\\([0-9][0-9.]*\\).deb"|\\n\\1|gp;'| sort -r -u -n -k1,1 -k2,2 -k3,3 -t.| head -1 | awk '{print $1}')
          LATEST_CHROME_RELEASE="lnx/chrome64_${LATEST_CHROME_VERSION}.deb"
          PACKAGE_ARCHIVE="chrome64_${CHROME_VERSION}.deb"
        fi
        echo "Latest Chrome version available on slimjet: '${LATEST_CHROME_VERSION}'"
        echo Installing Chrome version $CHROME_VERSION
        export URL="http://www.slimjetbrowser.com/chrome/${LATEST_CHROME_RELEASE}"
        cd /vagrant
        if [ -e $PACKAGE_ARCHIVE ]
        then
          echo Using already downloaded archive $PACKAGE_ARCHIVE
        else
          echo Downloading Chrome from $URL
          wget -nv $URL
        fi
        apt-get install -qqy libxss1 libappindicator1 libindicator7
        dpkg -i $PACKAGE_ARCHIVE
        # rm $PACKAGE_ARCHIVE
        cd /home/vagrant
      ;;
    esac
  else
    echo Download the latest Chrome
    # http://askubuntu.com/questions/79280/how-to-install-chrome-browser-properly-via-command-line
    cd /tmp
    wget -nv "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
    apt-get install -qqy libxss1 libappindicator1 libindicator7
    dpkg -i google-chrome-stable_current_amd64.deb
    rm google-chrome-stable_current_amd64.deb
    apt-get install -qqy -f google-chrome-stable
    cd -
  fi
  #=========================================================
  CHROMEDRIVER_VERSION='#{chromedriver_version}'
  if [[ $CHROMEDRIVER_VERSION ]] ; then
    echo "Download user specified version $CHROMEDRIVER_VERSION of Chromedriver"
  else
    echo Download latest Chromedriver
    CHROMEDRIVER_VERSION=$(curl -s "http://chromedriver.storage.googleapis.com/LATEST_RELEASE")
  fi
  PACKAGE_ARCHIVE='chromedriver_linux64.zip'
  cd /vagrant
  if [[ ! -e $PACKAGE_ARCHIVE ]]; then
    # possible platform options: linux32, linux64, mac64, win32
    PLATFORM=linux64
    URL="http://chromedriver.storage.googleapis.com/${CHROMEDRIVER_VERSION}/chromedriver_${PLATFORM}.zip"
    wget -O $PACKAGE_ARCHIVE -nv $URL
  fi
  cd /home/vagrant
  unzip -o "/vagrant/${PACKAGE_ARCHIVE}"
  chown vagrant:vagrant chromedriver
  echo Installed Chrome Driver version $(./chromedriver --version| head -1 | cut -f 2 -d ' ')
  echo Done
  #=========================================================
  GECKODRIVER_VERSION='#{geckodriver_version}'
  if [[ $GECKODRIVER_VERSION ]] ; then
    echo "Download the user specified version ${GECKODRIVER_VERSION} of Geckodriver."
  else
    echo Determine the latest version of GeckoDriver
    GECKO_RELEASE_URL='https://api.github.com/repos/mozilla/geckodriver/releases'
    # https://stedolan.github.io/jq/manual/#ConditionalsandComparisons
    # https://github.com/stedolan/jq/issues/370
    echo Processing list of GeckoDriver releases...
    # uncomment next line for debugging
    # curl -s -k $GECKO_RELEASE_URL | jq '.[] | .assets[] | .browser_download_url' | grep -v 'wires' | grep 'linux64' | sed 's/^.*\\///'
    GECKODRIVER_VERSION=$(curl -s -k $GECKO_RELEASE_URL | jq '.[] | .assets[] | .browser_download_url' | grep -v 'wires' | grep 'linux64' | sed 's/^.*\\///' | cut -f2 -d'-' | cut -f2,2,4 -d'.'| sort -rn | head -1 )
    GECKODRIVER_RELEASE=$(curl -s -k $GECKO_RELEASE_URL | jq '.[] | .assets[] | .browser_download_url' | grep -v 'wires' | grep 'linux64' | sed 's/^.*download\\///' | grep "$GECKODRIVER_VERSION" | tr -d '"')
  fi
  URL="https://github.com/mozilla/geckodriver/releases/download/${GECKODRIVER_RELEASE}"
  ARCHIVE='/var/tmp/geckodriver_linux64.tar.gz'
  echo Downloading GECKODRIVER version $GECKODRIVER_VERSION from $URL
  wget -O $ARCHIVE -nv $URL
  cd /home/vagrant
  tar -xzf $ARCHIVE
  chown vagrant:vagrant geckodriver
  echo Installed Gecko Driver version $(./geckodriver --version | head -1 | cut -f 2 -d ' ')
  # TODO: geckodriver ERROR Address in use (os error 98)
  #=========================================================
  USE_ORACLE_JAVA='#{use_oracle_java}'
  if [[ $USE_ORACLE_JAVA ]] ; then
    echo Downloading Oracle JDK
    # https://www.digitalocean.com/community/tutorials/how-to-manually-install-oracle-java-on-a-debian-or-ubuntu-vps
    pushd /vagrant
    PACKAGE_ARCHIVE='jdk-linux-x64.tar.gz'
    # In the past, needed to accept the license interactively in http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html to browse
    # URL="http://download.oracle.com/otn-pub/java/jdk/8u161-b12/2f38c3b165be4555a1fa6e98c45e0808/jdk-8u161-linux-x64.tar.gz"
    URL="http://download.oracle.com/otn-pub/java/jdk/8u191-b12/2787e4a523244c269598db4e85c51e0c/jdk-8u191-linux-x64.tar.gz"
    wget -O $PACKAGE_ARCHIVE --header "Cookie: oraclelicense=accept-securebackup-cookie" -nv $URL
    mkdir /opt/oracle-jdk 2>/dev/null
    tar -zxf $PACKAGE_ARCHIVE -C /opt/oracle-jdk
    # When installing from downloaded archive will also set the path manually
    JAVA_INSTALL_DIR=$(find '/usr/lib/jvm/' -maxdepth 1 -type d -name '*oracle*' )
    #
    update-alternatives --install /ust/bin/java java "${JAVA_INSTALL_DIR}/bin/java" 100
    update-alternatives --set java "${JAVA_INSTALL_DIR}/bin/java"
    update-alternatives --install /ust/bin/javac javac "${JAVA_INSTALL_DIR}/bin/javac" 100
    update-alternatives --set javac "${JAVA_INSTALL_DIR}/bin/javac"
  fi
fi
PROVISION_YANDEX='#{provision_yandex}'
# if [[ $PROVISION_YANDEX ]] ; then
# TODO:
# https://www.linuxbabe.com/browser/yandex-browser-debian-ubuntu-fedora-opensuse-arch
# add to sources list
# sudo cat<<EOF>/etc/apt/sources.list.d/yandex-browser.list
# deb [arch=amd64] http://repo.yandex.ru/yandex-browser/deb beta main
# EOF
# download and import the GPG key so that packages downloaded from this repository can be authenticated.
# wget https://repo.yandex.ru/yandex-browser/YANDEX-BROWSER-KEY.GPG
# sudo apt-key add YANDEX-BROWSER-KEY.GPG
# sudo apt update
# sudo apt install -qqy yandex-browser-beta
# fi
PROVISION_KATALON='#{provision_katalon}'
if [[ $PROVISION_KATALON ]] ; then
  # based on scripts in https://github.com/katalon-studio/docker-images
  pushd /vagrant

  KATALON_INSTALL_DIR_PARENT='/opt'
  # the /vagrant will be unmounted during the reboot
  # KATALON_INSTALL_DIR_PARENT='/vagrant'
  # NOTE: some earlier Katalon studi buids had archive broken:
  # file Katalon_Studio_Linux_64-5.5.tar.gz
  # Katalon_Studio_Linux_64-5.5.tar.gz: dat
  KATALON_VERSION_FULL='5.5.0'
  KATALON_VERSION='5.5'
  KATALON_VERSION_FULL='5.10.1'
  KATALON_VERSION='5.10.1'
  # NOTE:
  # <Error>
  # <Code>NoSuchKey</Code>
  # <Message>The specified key does not exist.</Message>
  # <Key>5.6.0/Katalon_Studio_Linux_64-5.6.tar.gz</Key>
  # <RequestId>52F0E5B631769126</RequestId>
  # <HostId>
  # dXza7X39zbPNaVMpOtWF+GnYUCV32w6NZldVb9Q0cBRSH/AePC67y/jY+y2k0+gFCK4p7b7a9EU=
  # </HostId>
  # </Error>
  # http://download.katalon.com/5.6.0/Katalon_Studio_Linux_64-5.6.tar.gz
  # To always get the latest version, sign-in
  # https://www.katalon.com/sign-in/
  # and use post one's account to download links with e.g.
  # https://backend.katalon.com/download?platform=linux_64&id=kouzmine_serguei%40yahoo.com
  # <input type="email" name="user_email" id="user_email" value="" placeholder="Email" required="" autofocus="">
  # <input type="password" name="user_pass" id="user_pass" value="" placeholder="Password" data-errormsg="Please choose a password with a minimum of 6 characters" required="">
  # <input style="width: auto; margin: 7px 10px 0 0;" type="checkbox" id="remember" name="remember" checked="checked">
  # <input class="sign-in" type="submit" id="login-btn" data-loading-text="Sign in" value="Sign in">
  # sign out
  # <a class="page-scroll button-change-hash" href="https://www.katalon.com/wp-login.php?action=logout&amp;redirect_to=https%3A%2F%2Fwww.katalon.com&amp;_wpnonce=469eba9ba4" title="Sign out">Sign out</a>
  # NOTE: GUI version recently become available https://docs.katalon.com/display/KD/Katalon+Studio+GUI+(beta)+for+Linux
  if [[ $KATALON_VERSION ]] ; then

    # NOTE: 5.5, 5.6.0 - still bad download, use manually downloaded cached copy to workaround
    PLATFORM='Linux_64'
    # possible platform options: Linux_32, Linux_64, mac64, win32
    PACKAGE_ARCHIVE="Katalon_Studio_${PLATFORM}-${KATALON_VERSION}.tar.gz"
    KATALON_HOME_DIRECTORY="Katalon_Studio_${PLATFORM}-${KATALON_VERSION}"
    KATALON_INSTALL_DIR="${KATALON_INSTALL_DIR_PARENT}/katalonstudio"
    if [ ! -e $PACKAGE_ARCHIVE ]; then
      echo 'Download Katalon'
      DOWNLOAD_URL="http://download.katalon.com/${KATALON_VERSION_FULL}/${PACKAGE_ARCHIVE}"
      wget -O $PACKAGE_ARCHIVE -nv $DOWNLOAD_URL
      # alternatively
      # curl -s -insecure -L -o $PACKAGE_ARCHIVE -k $DOWNLOAD_URL
    else
      echo 'Katalon is already downloaded.'
    fi
    echo 'Install Katalon'

    tar -zxsf $PACKAGE_ARCHIVE -C $KATALON_INSTALL_DIR_PARENT
    if [[ -d $KATALON_INSTALL_DIR ]] ; then
      mv $KATALON_INSTALL_DIR "${KATALON_INSTALL_DIR}.BAK"
    fi

    if [[ ! -d $KATALON_INSTALL_DIR ]] ; then
      mv $KATALON_INSTALL_DIR_PARENT/$KATALON_HOME_DIRECTORY $KATALON_INSTALL_DIR
    fi
    chown -R vagrant:vagrant $KATALON_INSTALL_DIR
    chmod u+x $KATALON_INSTALL_DIR/katalon
    # TODO: replace with link to the actual driver
    chmod u+x $KATALON_INSTALL_DIR/configuration/resources/drivers/chromedriver_linux64/chromedriver
    KATALON_KATALON_VERSION_FILE='/katalon/KATALON_VERSION'
    echo "Katalon Studio $KATALON_VERSION" >> $KATALON_KATALON_VERSION_FILE
    find $KATALON_INSTALL_DIR -name '*.sh' -exec chmod a+x {} \\;

  fi
  # based on: https://github.com/katalon-studio/docker-images/blob/master/katalon/src/scripts/katalon-execute.sh

  # replace the drivers:

  if [[ -e '/home/vagrant/chromedriver' ]] ; then
    EMBEDDED_DRIVER=$KATALON_INSTALL_DIR/configuration/resources/drivers/chromedriver_linux64/chromedriver
    pushd $(dirname $EMBEDDED_DRIVER)
    rm -f $EMBEDDED_DRIVER
    ln -s /home/vagrant/geckodriver
    popd
  fi
  if [[ -e '/home/vagrant/geckodriver' ]] ; then
    EMBEDDED_DRIVER=$KATALON_INSTALL_DIR/configuration/resources/drivers/firefox_linux64/geckodriver
    # pushd $(dirname $EMBEDDED_DRIVER)
    rm -f $EMBEDDED_DRIVER
    # ln -s /home/vagrant/geckodriver
    # popd
    ln -s -T /home/vagrant/geckodriver $EMBEDDED_DRIVER
    # failed to create symbolic link ‘/opt/katalonstudio/katalonstudio/configuration/resources/drivers/chromedriver_linux64/chromedriver’
    # : No such file or directory
  fi

  REPORT_FOLDER='/vagrant/reports'
  PROJECT_FILE='/vagrant/project.proj'
  KATALON_OPTS="-browserType='Chrome' -retry=0 -statusDelay=15 -testSuitePath='/vagrant/Test Suites/TS_RegressionTest'"
  $KATALON_INSTALL_DIR/katalon -runMode=console -reportFolder=$REPORT_FOLDER -projectPath=$PROJECT_FILE $KATALON_OPTS
  popd

  # Katalon Studio activation information
  # The token was generated by Katalon Studio itself when it was lanched and activated manually
  # the token seems to be unique per instance -
  # the presence of '~/.katalon/application.properties' does not stop Katalon Studio from promptimg for activation
  DEVELOPER_EMAIL='kouzmine_serguei@yahoo.com'
  ACTIVATION_TOKEN='1015_1836766539'
  KATALON_VERSION='5.10.1'
  cat <<EOF>'/home/vagrant/.katalon/application.properties'
#/home/vagrant/Desktop/Katalon_Studio_Linux_64-${KATALON_VERSION}
#Mon Feb 04 00:54:26 UTC 2019
activated=${ACTIVATION_TOKEN}
email=${DEVELOPER_EMAIL}
katalon.versionNumber=${KATALON_VERSION}
katalon.buildNumber=1
EOF
fi

PROVISION_VNC='#{provision_vnc}'
if [[ $PROVISION_VNC ]] ; then
  echo 'Install TigerVNC'

  PACKAGE_DEB=tigervncserver_1.6.0-3ubuntu1_amd64.deb
  DOWNLOAD_URL="https://bintray.com/artifact/download/tigervnc/stable/ubuntu-16.04LTS/amd64/tigervncserver_1.8.0-1ubuntu1_amd64.deb"
  curl -s -insecure -L -o $PACKAGE_DEB -k $DOWNLOAD_URL
  # wget -O $PACKAGE_DEB $DOWNLOAD_URL
  dpkg -qi $PACKAGE_DEB || apt -qqy -f install
  rm -f $PACKAGE_DEB
fi

#=========================================================
echo Set screen resolution
cat <<EOF>> /home/vagrant/.fluxbox/startup
xrandr -s 1280x800
EOF
#=========================================================
echo Install tmux scripts
cat <<EOF> tmux.sh
#!/bin/sh
if \\$(netstat -lp 2> /dev/null| grep -q X) ; then
  echo 'X already started'
else
  tmux start-server
fi

tmux new-session -d -s chrome-driver
tmux send-keys -t chrome-driver:0 'export DISPLAY=:0' C-m
tmux send-keys -t chrome-driver:0 './chromedriver' C-m

tmux new-session -d -s selenium
tmux send-keys -t selenium:0 '/usr/bin/xrandr -s 1280x800' C-m
tmux send-keys -t selenium:0 'export DISPLAY=:0' C-m

# NOTE options for java runtime.
tmux send-keys -t selenium:0 'java -Xmn512M -Xms1G -Xmx1G -jar selenium-server-standalone.jar' C-m
tmux send-keys -t selenium:0 'for cnt in {0..10}; do wget -O- http://127.0.0.1:4444/wd/hub; sleep 120; done' C-m

EOF

chmod +x tmux.sh
chown vagrant:vagrant tmux.sh
#=========================================================
echo Install startup scripts
cat <<EOF> /etc/X11/Xsession.d/9999-common_start
#!/bin/sh
/home/vagrant/tmux.sh &
xterm -fa fixed &
EOF
chmod +x /etc/X11/Xsession.d/9999-common_start
#=========================================================
echo -n 'Add host alias'
echo '192.168.33.1 host'| tee /etc/hosts
#=========================================================
echo Reboot the VM
sudo reboot

  END_OF_PROVISION
  config.vm.provider :virtualbox do |v|
    v.gui = true
    v.name = 'Selenium Fluxbox Trusty'
    v.customize ['modifyvm', :id, '--memory', box_memory, '--vram', '16', '--ioapic', 'on', '--cableconnected1', 'on', '--clipboard', 'bidirectional']
    v.customize ['setextradata', 'global', 'GUI/MaxGuestResolution', 'any']
    v.customize ['setextradata', :id, 'CustomVideoMode1', '1280x800x32']
    # VBoxManage controlvm 'Selenium Fluxbox Trusty' setvideomodehint 1280 800 32
  end
end

