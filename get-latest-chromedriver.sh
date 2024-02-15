#!/bin/sh

PLATFORM='linux64'
TMPFILE="/tmp/chrome-for-testing.$$.html"
DRIVERFILE='/tmp/chromedriver-linux64.zip'
URL='https://googlechromelabs.github.io/chrome-for-testing/'
curl -sko $TMPFILE $URL
echo "Examine $TMPFILE"
VERSION=$(xmllint --htmlout --html --xpath "//div[@class='table-wrapper summary']/table/tbody/tr[th/a/text()='Stable']/td[1]/code/text()" $TMPFILE 2>/dev/null)
echo "About to download chromedriver version $VERSION"
DRIVERURL=$(xmllint --htmlout --html --xpath "//section[@id='stable']/div[@class='table-wrapper']/table/tbody/tr[th/code='chromedriver' and td/code='200' and th/code='$PLATFORM']/td[1]/code/text()" $TMPFILE 2>/dev/null)
rm -f $TMPFILE

echo "About to download chromedriver URL $DRIVERURL"
curl -sko $DRIVERFILE $DRIVERURL
echo "Verify contents of $DRIVERFILE"
unzip -t $DRIVERFILE 
#
# https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/119.0.6045.105/linux64/chromedriver-linux64.zip
# echo unzip -d '/tmp/' -u $DRIVERFILE
unzip -d '/tmp/' -u $DRIVERFILE
cp /tmp/chromedriver-linux64/chromedriver ~/Downloads
~/Downloads/chromedriver -version
rm -f $DRIVERFILE
