#!/bin/sh
# NOTE: the page https://googlechromelabs.github.io/chrome-for-testing/ contains the remark: 
# Consult <a href=https://github.com/GoogleChromeLabs/chrome-for-testing#json-api-endpoints>our JSON API endpoints</a> if you’re looking to build automated scripts based on Chrome for Testing release data.
# however the linked page is also an HTML page and to get just the JSON open the link https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json

JSONFILE='/tmp/get-latest-chromedriver.json'
URL='https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json'
DRIVERFILE='/tmp/chromedriver-linux64.zip'
curl -ko $JSONFILE $URL
echo "inspecting ${JSONFILE}"
echo "NOTE: the following query will show both chrome and chromedriver download links:"
jq -cr '.channels.Stable.downloads[][]|select(.platform=="linux64").url'  $JSONFILE

echo "NOTE: the following query will show just the  chromedriver download link:"
jq -cr '.channels.Stable.downloads.chromedriver[]|select(.platform=="linux64").url' $JSONFILE
DRIVERURL=$(jq -cr '.channels.Stable.downloads.chromedriver[]|select(.platform=="linux64").url' $JSONFILE)
rm -f $JSONFILE
echo "curl -k -I $DRIVERFILE $DRIVERURL"
curl -k -I $DRIVERURL
echo "curl -k -o $DRIVERFILE $DRIVERURL"
curl -k -o $DRIVERFILE $DRIVERURL
echo "Verify contents of $DRIVERFILE"
unzip -t $DRIVERFILE 
# echo unzip -d '/tmp/' -u $DRIVERFILE
echo 'Stopping chromedriver'
# NOTE: prevent error with the lock:
# cp: cannot create  regular file '...chromedriver': Text file busy
killall chromedriver
unzip -d '/tmp/' -f -u $DRIVERFILE
# TODO: handle
# archive:  /tmp/chromedriver-linux64.zip
# replace /tmp/chromedriver-linux64/LICENSE.chromedriver? [y]es, [n]o, [A]ll, [N]one, [r]ename: A

cp /tmp/chromedriver-linux64/chromedriver ~/Downloads
~/Downloads/chromedriver -version
rm -f $DRIVERFILE
# to check the chrome browser version on Linux need to run the executable with the version option:
# google-chrome -version
# Google Chrome 124.0.6367.60
