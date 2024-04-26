#Copyright (c) 2023,2024 Serguei Kouzmine
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in
#all copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#THE SOFTWARE.

param (
  [string]$url = 'https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json',
  [switch]$debug

)
[bool]$debug_flag = [bool]$psboundparameters['debug'].ispresent

# NOTE:
# 'https://googlechromelabs.github.io/chrome-for-testing/' is html
# NOTE:
# https://chromedriver.storage.googleapis.com/index.html?path=109.0.5414.74/
# for Windows 7 and Windows 8
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
if ($debug_flag) {
  Invoke-WebRequest -uri $url
}
# https://stackoverflow.com/questions/18770723/hide-progress-of-invoke-webrequest
$ProgressPreference = 'SilentlyContinue'
$result = Invoke-WebRequest -uri $url
$ProgressPreference = 'Continue'
$o = $result.Content| convertfrom-json
if ($debug_flag) {
  # NOTE: is quite big for printing in console
  write-host ($o |convertto-json -depth 5)
}
$o.channels.Stable.downloads.chromedriver | where-object { $_.platform -eq 'win64' } | select-object -expandproperty url | set-variable -name driverurl

$driverfile = $env:TEMP + '\' + 'chromedriver-win64.zip'
if ($debug_flag) {
  write-host ('Invoke-WebRequest -uri {0} -OutFile {1} -passthru' -f $driverurl, $driverfile)
}

$ProgressPreference = 'SilentlyContinue'
$response = Invoke-WebRequest -uri $driverurl -OutFile $driverfile -passthru
$ProgressPreference = 'Continue'
# NOTE: do not print the full $response: which has heavy RawContent
if ($debug_flag) {
  write-host $response.StatusCode
}
get-item -path $driverfile

# alternatively use invoke-restmethod cmdlet, will have the result in JSON

$content_type = 'application/json'
if ($debug_flag) {
  write-host ('invoke-restmethod -uri {0} -method Get -contenttype {1}' -f $url, $content_type)
}
$ProgressPreference = 'SilentlyContinue'
$result = invoke-restmethod -uri $url -method Get -contenttype $content_type
$ProgressPreference = 'Continue'

$result.channels.Stable.downloads.chromedriver | where-object { $_.platform -eq 'win64' } | select-object -expandproperty url | set-variable -name driverurl
write-host  ('will download driver from URL {0}' -f $driverurl)
$script_path = (get-location).path
cd $env:temp
expand-archive chromedriver-win64.zip -Force
get-process -name 'ChromeDriver' -erroraction silentlycontinue | stop-process
copy-item .\chromedriver-win64\chromedriver-win64\chromedriver.exe "${env:userprofile}\Downloads\chromedriver.exe" -force
cd $script_path

get-item "${env:userprofile}\Downloads\chromedriver.exe"  | select-object -property VersionInfo.ProductVersion

# NOTE: ProductVersion of the chromedriver.exe is often blank

& "${env:userprofile}\Downloads\chromedriver.exe" -version

# Program 'chromedriver.exe' failed to run: The specified executable is not a valid application for this OS platform.
# NOTE: last supported of Chrome browse for Windows 7 and 8.1 is 109
# Later builds of chrome driver is not compatible with older versions of Windows:

# Windows 10
# ChromeDriver 123.0.6312.86 (9b72c47a053648d405376c5cf07999ed626728da-refs/branch-heads/6312@{#698})

# Windows 7
# This version of C:\Users\sergueik\Desktop\chromedriver.exe is not compatible with the version of Windows you're running. 
# Check your computer's system information to see whether you need a x86 (32-bit) or x64 (64-bit) version of the program, and then contact the software publisher.
# Windows 8.1
# this app can't run on your PC

# to check the chrome browser version on windows need to examine the file metadata
#
# get-item -path 'C:\Program Files\Google\Chrome\Application\chrome.exe' | select-object -expandproperty VersionInfo | select-object -expandproperty ProductVersion
# wll return
# 124.0.6367.92
# alternatively use semantic fields explicitly
# $o = get-item -path 'C:\Program Files\Google\Chrome\Application\chrome.exe' | select-object -expandproperty VersionInfo | select-object -first 1
# write-output ('{0}.{1}.{2}.{3}' -f $o.ProductMajorPart,$o.ProductMinorPart,$o.ProductBuildPart,$o.ProductPrivatePart)


