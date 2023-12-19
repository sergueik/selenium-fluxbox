#!/bin/sh
# NOTE: the page https://googlechromelabs.github.io/chrome-for-testing/ contains the remark: 
# Consult <a href=https://github.com/GoogleChromeLabs/chrome-for-testing#json-api-endpoints>our JSON API endpoints</a> if you’re looking to build automated scripts based on Chrome for Testing release data.
# however the linked page is also an HTML page and to get just the JSON open the link https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json

SCRIPTDIR=$(pwd)
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
cd /tmp
unzip -x -o $DRIVERFILE
cp chromedriver-linux64/chromedriver ~/Downloads
rm -f $DRIVERFILE
cd $SCRIPTDIR
