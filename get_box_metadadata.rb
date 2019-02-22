# -*- mode: ruby -*-

require 'fileutils'
require 'find'
require 'json'
require 'net/http'
require 'openssl'
require 'pathname'
require 'pp'
require 'uri'

@debug = false
net = Net::HTTP.new('vagrantcloud.com', 443)
net.use_ssl = true
# https://www.engineyard.com/blog/ruby-ssl-error-certificate-verify-failed
# certificate verify failed (OpenSSL::SSL::SSLError)
net.verify_mode = OpenSSL::SSL::VERIFY_NONE

response = net.get('/ubuntu/boxes/trusty64/')
location = response.response['location'].to_s
if @debug
  $stderr.puts ('Body = ' + response.body)
  $stderr.puts ('Message = ' + response.message)
  $stderr.puts ('Code = ' + response.code)
  $stderr.puts ('Location = ' + location)
end
puts ('Opening the location ' + location )
redirect_url = URI.parse(location)
net = Net::HTTP.new(redirect_url.host,redirect_url.port)
net.use_ssl = true
net.verify_mode = OpenSSL::SSL::VERIFY_NONE
response = net.get(redirect_url.path)
if @debug
  pp response.body
end
metadata = JSON.parse(response.body)
pp metadata
pp metadata['versions'][0]['version']