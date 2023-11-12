#Copyright (c) 2023 Serguei Kouzmine
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
  [string]$url ='https://googlechromelabs.github.io/chrome-for-testing/'
)
# use invoke-restmethod cmdlet to read page, but
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'

$result = Invoke-WebRequest -uri $url
$o = $result.Content| convertfrom-json

$o.channels.Stable.downloads.chromedriver | where-object { $_.platform -eq 'win64' } | select-object -expandproperty url | set-variable -name driverurl
write-host  ('will download driver from URL {0}' -f $driverurl)

write-host ('Invoke-WebRequest -uri {0} -OutFile {1} -passthru' -f $url, $outfile)

$driverfile = $env:TEMP + '\' + 'chromedriver-win64.zip'
$response  = Invoke-WebRequest -uri  $driverurl -OutFile $driverfile -passthru
write-output $response 
get-item -path $driverfile

