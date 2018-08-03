provision_selenium = ENV.fetch('PROVISION_SELENIUM', '')
selenium_version = ENV.fetch('SELENIUM_VERSION', '')
chromedriver_version = ENV.fetch('CHROMEDRIVER_VERSION', '')
firefox_version = ENV.fetch('FIREFOX_VERSION', '')
geckodriver_version = ENV.fetch('GECKODRIVER_VERSION', '')
use_oracle_java = ENV.fetch('USE_ORACLE_JAVA', '')
debug = ENV.fetch('DEBUG', '')

# check if requested Chrome version is available on http://www.slimjetbrowser.com/chrome/
available_chrome_versions = %w|
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
  puts "Specific old Chrome versions available from https://www.slimjet.com/chrome/google-chrome-old-version.php:\n" + available_chrome_versions.join("\n")
  exit
end

VAGRANTFILE_API_VERSION = '2'
basedir = ENV.fetch('HOME','') || ENV.fetch('USERPROFILE', '')
box_memory = ENV.fetch('BOX_MEMORY', '2048').to_i
basedir = basedir.gsub('\\', '/')
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = 'ubuntu/trusty64'
  # Localy cached vagrant box image from https://vagrantcloud.com/ubuntu/boxes/trusty64/versions/14.04/providers/virtualbox.box
  # see also http://www.vagrantbox.es/ and http://dev.modern.ie/tools/vms/linux/
  config_vm_box_name = 'trusty-server-amd64-vagrant-selenium.box'
  config.vm.box_url = "file://#{basedir}/Downloads/#{config_vm_box_name}"
  config.vm.network :forwarded_port, guest:4444, host:4444
  config.vm.network :private_network, ip: '192.168.33.10'
  config.vm.boot_timeout = 600
  # Configure common synced folder
  config.vm.synced_folder './' , '/vagrant'
  config.vm.provision 'shell', inline: <<-END_OF_PROVISION
#!/bin/bash
DEBUG='#{debug}'
if [[ -z $DEBUG ]] ; then
set -x
fi

#=========================================================
echo Install the packages
apt-get -qq update
apt-get -qqy install fluxbox xorg unzip vim default-jre rungetty wget jq
#=========================================================
echo Install the OpenJDK 8 backport for trusty
if false ; then
  # installing the oracle 8 JDK from ppa:webupd8team/java still stops on Oracle Licence Agreement prompt
  # for alternative install set USE_ORACLE_JAVA
  add-apt-repository ppa:webupd8team/java -y
  apt-get -qq update
  apt-get -qqy install oracle-java8-installer
  apt-get -qqy install oracle-java8-set-default
  # when installing from downloaded archive will also need
  # update-alternatives --install /ust/bin/java /usr/lib/jvm/jdk-1.8.0_161/bin/java java 0
  # update-alternatives --set java /usr/lib/jvm/jdk-1.8.0_161/bin/java
  # update-alternatives --set javac /usr/lib/jvm/jdk-1.8.0_161/bin/javac

fi
add-apt-repository -y ppa:openjdk-r/ppa
apt-get -qqy update
apt-get install -qqy openjdk-8-jdk
update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java
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
  if [[ $SELENIUM_VERSION ]] ; then
    echo Download Selenium version $SELENIUM_VERSION
    SELENIUM_RELEASE=$(curl -# "https://selenium-release.storage.googleapis.com/" | sed -n "s/.*<Key>\\\\(${SELENIUM_VERSION}\\\\/selenium-server-standalone[^<][^>]*\\\\)<\\\\/Key>.*/\\\\1/p")
  else
    echo Download latest Selenium Server
    SELENIUM_RELEASE=$(curl -# https://selenium-release.storage.googleapis.com/ | sed -n 's/.*<Key>\\([^>][^>]*selenium-server-standalone[^<][^<]*\\)<\\/Key>.*/\\1/p')
    SELENIUM_VERSION=$(echo $SELENIUM_RELEASE | sed -n 's/.*selenium-server-standalone-\\([0-9][0-9.]*\\).jar/\\1/p')
  fi
  PACKAGE_ARCHIVE="selenium-server-standalone-${SELENIUM_VERSION}.jar"
  cd /vagrant
  if [ ! -e $PACKAGE_ARCHIVE ] ; then
    URL="https://selenium-release.storage.googleapis.com/${SELENIUM_RELEASE}"
    echo Downloading Selenium $PACKAGE_ARCHIVE from $URL
    wget -O $PACKAGE_ARCHIVE -nv $URL
  else
    echo Using already downloaded $PACKAGE_ARCHIVE
  fi
  cp $PACKAGE_ARCHIVE /home/vagrant/selenium-server-standalone.jar
  cd /home/vagrant
  chown vagrant:vagrant selenium-server-standalone.jar
  #=========================================================
  CHROME_VERSION='#{chrome_version}'
  if [[ $CHROME_VERSION ]]; then
    echo installing libnss3
    # https://stackoverflow.com/questions/46126902/fix-nss-version-not-match-when-update-chrome-in-ubuntu
    # for trusty need the following command may get the correct version of libnss3, which is a prerequisite of Chrome 64+
    apt-get -qqy install --only-upgrade libnss3
    echo "installing Chrome $CHROME_VERSION"
    case $CHROME_VERSION in
    beta|stable|unstable)
        # as of December 2017 the https://dl.google.com/linux/chrome/deb is occasionally 404 and this will fail (and fail to detect it did fail)
        # and the only way to install stable Chrome is to interactiely download it
        # https://www.google.com/linuxrepositories/
        # http://www.allaboutlinux.eu/install-google-chrome-in-debian-8/
        wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
        # may need a second time for some reason sporadic error
        # GPG error: http://dl.google.com stable Release: The following signatures couldn't be verified because the public key is not available: NO_PUBKEY 1397BC53640DB551
        apt-add-repository http://dl.google.com/linux/chrome/deb/
        apt-get -qq update
        apt-get install google-chrome-${CHROME_VERSION}
      ;;
      *)
        wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
        apt-get remove -qqy -f google-chrome-stable
        apt-get -qqy install libxml2-utils
        LATEST_CHROME_VERSION=$(curl -# https://www.slimjet.com/chrome/google-chrome-old-version.php| grep 'download-chrome.php?file=lnx'| sed -n 's/<tr>/\\n\\n/gp'|sed -n "s/.*<a href='download-chrome.php?file=lnx%2Fchrome64_[0-9][0-9_.]*\\.deb'>\\([0-9][0-9.]*\\)<.*$/\\1/p" | sort -r -u -n -k1,1 -k2,2 -t.| head -1)
        echo latest Chrome version available on slimjet: $LATEST_CHROME_VERSION
        # Alternatively use xmllint
        # TODO: fix trailing whitespace
        curl -# https://www.slimjet.com/chrome/google-chrome-old-version.php -o /tmp/a.html
        LATEST_CHROME_VERSION=$(xmllint --htmlout --html --xpath "//table[3]//tr/td/a[contains(@href,'file=lnx')]/@href" /tmp/a.html 2> /dev/null | sed 's|href="download-chrome.php?file=lnx%2Fchrome64_|\\n|gp;' | sed 's|\\.deb"||' | sort -ru | head -1)
        echo "Latest Chrome version available on slimjet: '${LATEST_CHROME_VERSION}'"
        LATEST_CHROME_VERSION=$(xmllint --htmlout --html --xpath "//table[3]//tr/td/a[contains(@href,'file=lnx')]/@href" /tmp/a.html 2> /dev/null | sed 's|href="download-chrome.php?file=lnx%2Fchrome64_\\([0-9][0-9.]*\\).deb"|\\n\\1|gp;'| sort -ru | head -1 | awk '{print $1}')
        echo "Latest Chrome version available on slimjet: '${LATEST_CHROME_VERSION}'"
        echo Installing Chrome version $CHROME_VERSION
        export URL="http://www.slimjetbrowser.com/chrome/lnx/chrome64_${CHROME_VERSION}.deb"
        cd /vagrant
        PACKAGE_ARCHIVE="chrome64_${CHROME_VERSION}.deb"
        if [ ! -e $PACKAGE_ARCHIVE ] ; then
          echo Downloading Chrome from $URL
          wget -nv $URL
        else
          echo Using already downloaded archive $PACKAGE_ARCHIVE
        fi
        apt-get install -qqy libxss1 libappindicator1 libindicator7
        dpkg -i "chrome64_${CHROME_VERSION}.deb"
        # rm "chrome64_${CHROME_VERSION}.deb"
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
    CHROMEDRIVER_VERSION=$(curl -# "http://chromedriver.storage.googleapis.com/LATEST_RELEASE")
    # alternartively
    CHROMEDRIVER_VERSION=$(curl -k https://chromedriver.storage.googleapis.com/ | xmllint --xpath '//*[local-name()="Contents"]/*[local-name()="Key"]' - | sed 's/<\\/*Key>/\\n/g' | sed -n 's/\\([0-9]\\.[0-9][0-9]*\\)\\/chromedriver_linux64.zip/\\1/p' | sort -V -r | head -1)
    # NOTE: the intermediate xmllint output in the above is not a valid XML
  fi
  PACKAGE_ARCHIVE='chromedriver_linux64.zip'
  cd /vagrant
  if [ ! -e $PACKAGE_ARCHIVE ]; then
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
    echo Determine the latest version of Geckodriver
    GECKODRIVER_VERSION=$(curl -insecure -L -# https://github.com/mozilla/geckodriver/releases | sed -n 's/.*<a href="\\/mozilla\\/geckodriver\\/releases\\/download\\/v\\([0-9.][0-9.]*\\)\\/geckodriver-.*-linux64.*/\\1/p' | head -1)
    # alternatively
    GECKO_RELEASE_URL='https://api.github.com/repos/mozilla/geckodriver/releases'
    GECKODRIVER_VERSION=$(curl -k $GECKO_RELEASE_URL | jq '.[] | .assets[] | .browser_download_url' | grep -v 'wires' | grep 'linux64' | sed 's/^.*\///' | cut -f2 -d'-' | cut -f2,2,4 -d'.'| sort -n | head-1)  fi
  fi
  URL="https://github.com/mozilla/geckodriver/releases/download/v${GECKODRIVER_VERSION}/geckodriver-v${GECKODRIVER_VERSION}-linux64.tar.gz"
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
    # need to accept the license interactively in http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html to browse
    URL="http://download.oracle.com/otn-pub/java/jdk/8u161-b12/2f38c3b165be4555a1fa6e98c45e0808/jdk-8u161-linux-x64.tar.gz"
    wget -O $PACKAGE_ARCHIVE --header "Cookie: oraclelicense=accept-securebackup-cookie" -nv $URL
    mkdir /opt/oracle-jdk 2>/dev/null
    tar -zxf $PACKAGE_ARCHIVE -C /opt/oracle-jdk
    update-alternatives --install /usr/bin/java java /opt/oracle-jdk/jdk1.8.0_161/bin/java 100
    update-alternatives --set java /opt/oracle-jdk/jdk1.8.0_161/bin/java
    update-alternatives --install /usr/bin/javac javac /opt/oracle-jdk/jdk1.8.0_161/bin/javac 100
    update-alternatives --set javac /opt/oracle-jdk/jdk1.8.0_161/bin/javac
    popd
  fi
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
if $(netstat -lp | grep X) ; then
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
    v.customize ['modifyvm', :id, '--memory', box_memory ]
    v.customize ['modifyvm', :id, '--vram', '16']
    v.customize ['modifyvm', :id, '--clipboard', 'bidirectional']
    v.customize ['setextradata', 'global', 'GUI/MaxGuestResolution', 'any']
    v.customize ['setextradata', :id, 'CustomVideoMode1', '1280x800x32']
    v.customize ['modifyvm', :id, '--cableconnected1', 'on']
    # VBoxManage controlvm 'Selenium Fluxbox Trusty' setvideomodehint 1280 800 32
  end
end
