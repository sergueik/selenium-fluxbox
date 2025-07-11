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

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
if ($debug_flag) {
  Invoke-WebRequest -uri $url
}
$result = Invoke-WebRequest -uri $url
$o = $result.Content| convertfrom-json
if ($debug_flag) {
  # NOTE: is quite big for printing in console
  write-host ($o |convertto-json -depth 5)
}
# NOTE $o.versions is an array of
<#
[
 {
    "version":  "115.0.5790.170",
    "revision":  "1148114",
    "downloads":  {
                      "chrome":  [
                                     {
                                         "platform":  "linux64",
                                         "url":  "https://storage.googleapis.com/chrome-for-testing-public/115.0.5790.170/linux64/chrome-linux64.zip"
                                     },
                                     {
                                         "platform":  "mac-arm64",
                                         "url":  "https://storage.googleapis.com/chrome-for-testing-public/115.0.5790.170/mac-arm64/chrome-mac-arm64.zip"
                                     },
                                     {
                                         "platform":  "mac-x64",
                                         "url":  "https://storage.googleapis.com/chrome-for-testing-public/115.0.5790.170/mac-x64/chrome-mac-x64.zip"
                                     },
                                     {
                                         "platform":  "win32",
                                         "url":  "https://storage.googleapis.com/chrome-for-testing-public/115.0.5790.170/win32/chrome-win32.zip"
                                     },
                                     {
                                         "platform":  "win64",
                                         "url":  "https://storage.googleapis.com/chrome-for-testing-public/115.0.5790.170/win64/chrome-win64.zip"
                                     }
                                 ],
                      "chromedriver":  [
                                           {
                                               "platform":  "linux64",
                                               "url":  "https://storage.googleapis.com/chrome-for-testing-public/115.0.5790.170/linux64/chromedriver-linux64.zip"
                                           },
                                           {
                                               "platform":  "mac-arm64",
                                               "url":  "https://storage.googleapis.com/chrome-for-testing-public/115.0.5790.170/mac-arm64/chromedriver-mac-arm64.zip"
                                           },
                                           {
                                               "platform":  "mac-x64",
                                               "url":  "https://storage.googleapis.com/chrome-for-testing-public/115.0.5790.170/mac-x64/chromedriver-mac-x64.zip"
                                           },
                                           {
                                               "platform":  "win32",
                                               "url":  "https://storage.googleapis.com/chrome-for-testing-public/115.0.5790.170/win32/chromedriver-win32.zip"
                                           },
                                           {
                                               "platform":  "win64",
                                               "url":  "https://storage.googleapis.com/chrome-for-testing-public/115.0.5790.170/win64/chromedriver-win64.zip"
                                           }
                                       ]
                  }
}
]

#>
# NOTE: not all versions have chromedriver in downloads

$o.channels.Stable.downloads.chromedriver | where-object { $_.platform -eq 'win64' } | select-object -expandproperty url | set-variable -name driverurl

$driverfile = $env:TEMP + '\' + 'chromedriver-win64.zip'
if ($debug_flag) {
  write-host ('Invoke-WebRequest -uri {0} -OutFile {1} -passthru' -f $driverurl, $driverfile)
}

$response = Invoke-WebRequest -uri $driverurl -OutFile $driverfile -passthru
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
$result = invoke-restmethod -uri $url -method Get -contenttype $content_type

$result.channels.Stable.downloads.chromedriver | where-object { $_.platform -eq 'win64' } | select-object -expandproperty url | set-variable -name driverurl
write-host  ('will download driver from URL {0}' -f $driverurl)
$script_path = (get-location).path
cd $env:temp
expand-archive chromedriver-win64.zip -Force
get-process -name 'ChromeDriver' -erroraction silentlycontinue | stop-process
copy-item .\chromedriver-win64\chromedriver-win64\chromedriver.exe "${env:userprofile}\Downloads\chromedriver.exe" -force
cd $script_path
get-item "${env:userprofile}\Downloads\chromedriver.exe"  | select-object -property VersionInfo.ProductVersion
# blank

& "${env:userprofile}\Downloads\chromedriver.exe" -version
