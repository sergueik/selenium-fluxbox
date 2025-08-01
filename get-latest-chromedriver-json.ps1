#Copyright (c) 2023-2025 Serguei Kouzmine
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



# NOTE: on Windows 8.1 and below need alternative method:
# expand-archive : The term 'expand-archive' is not recognized as the name of acmdlet, function, script file, or operable program. Check the spelling of the name, or if a path was included, verify that the path is correct and try again.


expand-archive chromedriver-win64.zip -force -erroraction silentlycontinue

# https://learn.microsoft.com/en-us/dotnet/api/system.io.compression.zipfile.extracttodirectory?view=netframework-4.8
# 	https://learn.microsoft.com/en-us/dotnet/standard/io/how-to-compress-and-extract-files
# Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem,
# Requires .NET Framework 4.5 or later
add-type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem 

remove-item -path "${env:TEMP}\chromedriver-win64\chromedriver-win64" -recurse -Force -erroraction silentlycontinue
# [System.IO.Compression.ZipFile]::ExtractToDirectory('chromedriver-win64.zip', 'chromedriver-win64')
# NOTE: cannot rely on current dir change and use relative paths when operating through System.IO.Compression.ZipFile

# NOTE:
# The $true parameter will overwrite existing files - valid for .Net only
# argument signature change between .Net Framework and .Net (uncomment to reproduce):
# Cannot convert argument "entryNameEncoding", with value: "True", for "ExtractToDirectory" to type "System.Text.Encoding": "Cannot convert value "True" to type "System.Text.Encoding". Error: "Invalid cast from 'System.Boolean' to 'System.Text.Encoding'.""

# can also use a third-party tool like 7-Zip
[System.IO.Compression.ZipFile]::ExtractToDirectory("${env:TEMP}\chromedriver-win64.zip", "${env:TEMP}\chromedriver-win64\"  <# , $true  #>)


# start-process 'C:\Program Files\7-Zip\7z.exe' -ArgumentList "x ""chromedriver-win64.zip"" -o""chromedriver-win64""" -wait

get-process -name 'ChromeDriver' -erroraction silentlycontinue | stop-process
copy-item .\chromedriver-win64\chromedriver-win64\chromedriver.exe "${env:userprofile}\Downloads\chromedriver.exe" -force
cd $script_path

get-item "${env:userprofile}\Downloads\chromedriver.exe"  | select-object -property VersionInfo.ProductVersion

# NOTE: ProductVersion of the chromedriver.exe is often blank

& "${env:userprofile}\Downloads\chromedriver.exe" -version
# NOTE: Windows 8.1 and below

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
# Get-ItemPropertyValue cmdlet is to retrieve the value of a specific property of an item in the reistry with PowerShell 
# 'App Paths' is where system keeps known application paths 
# Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe'
# Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe' -name '(default)'|set-variable -name  application_path

# get-item -path $application_path | select-object -expandproperty VersionInfo | select-object -expandproperty ProductVersion
# wll return
# 124.0.6367.92
# alternatively use semantic field Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Pathss explicitly
# $o = get-item -path $application_path | select-object -expandproperty VersionInfo | select-object -first 1
# write-output ('{0}.{1}.{2}.{3}' -f $o.ProductMajorPart,$o.ProductMinorPart,$o.ProductBuildPart,$o.ProductPrivatePart)


