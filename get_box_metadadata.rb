# -*- mode: ruby -*-

require 'fileutils'
require 'find'
require 'json'
require 'net/http'
require 'openssl'
require 'optparse'
require 'pathname'
require 'pp'
require 'uri'

@debug = false

@options = {
  :debug   => false,
  :release => 'xenial64',
  :distro  => 'ubuntu',
}
options_defined = false
unless options_defined
  o = OptionParser.new
  o.on('--distro [DISTRO]', 'distro') do |val|
    @options[:distro] = val
  end

  o.on('--release [RELEASE]', 'release') do |val|
    @options[:release] = val
  end

  o.on('-d', '--debug', 'Debug') do |val|
    @options[:debug] = true
  end
  o.parse!
end
pp @options
release = @options[:release] || 'trusty64'
distro = @options[:distro] || 'ubuntu'

net = Net::HTTP.new('vagrantcloud.com', 443)
net.use_ssl = true
# https://www.engineyard.com/blog/ruby-ssl-error-certificate-verify-failed
# certificate verify failed (OpenSSL::SSL::SSLError)
net.verify_mode = OpenSSL::SSL::VERIFY_NONE

response = net.get("/#{distro}/boxes/#{release}/")
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
# pp metadata
pp metadata['versions'][0]['version']
# Usage:
# ruby get_box_metadadata.rb  --release alpine39 --distro generic
# "3.6.12"
# cd ~/Downloads
# curl -L -o alpine39_new.box https://app.vagrantup.com/generic/boxes/alpine39/versions/3.6.12/providers/virtualbox.box
#
# minimal Vagrantfile:
#  Vagrant.configure('2') do |config|
#
#    config.vm.box = 'generic/alpine39'
#    boxname = 'alpine39.box'
#    basedir = ENV.fetch('USERPROFILE', '')
#    basedir = ENV.fetch('HOME', '') if basedir == ''
#    basedir = basedir.gsub('\\', '/')
#    config.vm.box_url = "file://#{basedir}/Downloads/#{boxname}"
#    config.vm.network 'forwarded_port', guest: 80, host: 8080
# end
#
