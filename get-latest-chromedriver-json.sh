#!/bin/sh
# NOTE: the page https://googlechromelabs.github.io/chrome-for-testing/ contains the remark: 
# Consult <a href=https://github.com/GoogleChromeLabs/chrome-for-testing#json-api-endpoints>our JSON API endpoints</a> if you’re looking to build automated scripts based on Chrome for Testing release data.
# however the linked page is also an HTML page and to get just the JSON open the link https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json

TMPFILE='/tmp/get-latest-chromedriver.json'
URL='https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json'
DRIVERFILE='/tmp/chromedriver-linux64.zip'
curl -sko $TMPFILE $URL

# NOTE: the following query will show both chrome and chromedriver download links for Windows x64:  
jq '.channels.Stable.downloads[][]|select(.platform=="win64").url'  $TMPFILE

# the following query will show just the  chromedriver download link:
cat $TMPFILE | jq '.channels.Stable.downloads.chromedriver[]|select(.platform == "linux64")'

PLATFORM='linux64'
DRIVERURL=$(cat $TMPFILE | jq -cr ".channels.Stable.downloads.chromedriver[]|select(.platform == \"$PLATFORM\").url")
echo "Will download URL $DRIVERURL"
curl -sko $DRIVERFILE $DRIVERURL
echo "Verify contents of $DRIVERFILE"
unzip -t $DRIVERFILE 
rm -f $TMPFILE
