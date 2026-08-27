#!/bin/sh

VERSION=${1:-}

# NOTE: the page https://googlechromelabs.github.io/chrome-for-testing/ contains the remark: 
# Consult <a href=https://github.com/GoogleChromeLabs/chrome-for-testing#json-api-endpoints>our JSON API endpoints</a> if you’re looking to build automated scripts based on Chrome for Testing release data.
# however the linked page is also an HTML page and to get just the JSON open the link https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json
PLATROFM=linux64
JSONFILE='/tmp/get-latest-chromedriver.json'
DRIVERFILE='/tmp/chromedriver-linux64.zip'
if [ -z "$VERSION" ] ; then
  URL='https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json'
  curl -sko $JSONFILE $URL

  1>&2 echo "inspecting ${JSONFILE}"
  1>&2 echo "NOTE: the following query will show both chrome and chromedriver download links:"
  jq -cr '.channels.Stable.downloads[][]|select(.platform=="linux64").url' $JSONFILE

  1>&2 echo "NOTE: the following query will show just the  chromedriver download link:"
  jq -cr '.channels.Stable.downloads.chromedriver[]|select(.platform=="linux64").url' $JSONFILE
  DRIVERURL=$(jq -cr '.channels.Stable.downloads.chromedriver[]|select(.platform=="linux64").url' $JSONFILE)
else
  URL='https://googlechromelabs.github.io/chrome-for-testing/known-good-versions-with-downloads.json'
  curl -sko $JSONFILE $URL

  1>&2 echo "inspecting ${JSONFILE}"
  1>&2 echo "NOTE: the following query will show just the 1st chromedriver download link:"
  jq -r "[.versions[]|select(.version| test(\"$VERSION.\"))][1]|.downloads.chromedriver[]|select(.platform==\"linux64\").url" $JSONFILE  
  DRIVERURL=$(jq -r "[.versions[]|select(.version| test(\"$VERSION.\"))][0]|.downloads.chromedriver[]|select(.platform==\"linux64\").url" $JSONFILE  )
fi
rm -f $JSONFILE
1>&2 echo "curl -sk -I $DRIVERURL"
curl -sk -I $DRIVERURL
1>&2 echo "curl -sk -o $DRIVERFILE $DRIVERURL"
curl -sk -o $DRIVERFILE $DRIVERURL
1>&2 echo "Verify contents of $DRIVERFILE"
file $DRIVERFILE
unzip -t $DRIVERFILE
# echo unzip -d '/tmp/' -u $DRIVERFILE
# NOTE: prevent error with the lock:
# cp: cannot create  regular file '...chromedriver': Text file busy
ps ax | grep -q [c]hromedriver | tee /dev/null /dev/stderr
if [ ! $? ]
then
  echo 'Stopping chromedriver'
  killall chromedriver
fi
# SCRIPTDIR=$(pwd)
# cd $(dirname $DRIVERFILE)
# ls $DRIVERFILE
1>&2 echo unzip -d '/tmp/' -u $DRIVERFILE
rm -fr /tmp/chromedriver-linux64
unzip -d '/tmp/' -u $DRIVERFILE
1>&2 echo 'Done'
ls /tmp/chromedriver-linux64 | tee /dev/null /dev/stderr
cp /tmp/chromedriver-linux64/chromedriver "$HOME/Downloads"
1>&2 echo 'Downloaded verson:'
"$HOME/Downloads/chromedriver" -version
rm -f $DRIVERFILE
# to check the chrome browser version on Linux need to run the executable with the version option:
# google-chrome -version
# Google Chrome 124.0.6367.60
# cd $SCRIPTDIR
