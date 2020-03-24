#!/usr/bin/env ruby
# NOTE: cannot use "$@" or $0 - gets passed verbatim

# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'uri'
require 'net/https'
require 'pp'
require 'optparse'

options = {}
# NOTE: too greedy
# TODO: get options "the right way" ?
if $0 == __FILE__
  options = ARGV.getopts('vdr:', 'verbose', 'debug', 'release:')
  options[:verbose] = options['v'] || options['verbose']
  options[:debug] = options['d'] || options['debug']
  options[:release] = options['r'] || options['release']
  options[:file] = $0
  options.each do |k,_|
    options.delete(k) if k.kind_of? String
  end	
else

  OptionParser.new do |opts|
    opts.banner = 'Usage: example.rb [options]'
    opts.on('-v', '--[no-]verbose', 'Run verbosely') do |data|
      options[:verbose] = data
    end
    opts.on('-d', '--debug', 'Run in debug mode') do |data|
      options[:debug] = data

    end
    opts.on('-rRELEASE', '--release=RELEASE', 'Return the build number of closest match available for specific RELEASE of Chrome') do |data|
      options[:release] = data
    end
  end.parse!

end

$DEBUG = options[:debug]
if $DEBUG
  PP.pp options, $stderr
  # exit 0
end
$RELEASE = options[:release]
$VERBOSE = options[:verbose]
$BASE_DOWNLOAD='http://www.slimjetbrowser.com/chrome'

# optionally when there is gem, use it
# https://airbrake.io/blog/ruby-exception-handling/loaderror
has_nokogiri = false
begin
  require 'nokogiri'
  if $DEBUG
    $stderr.puts 'Loading "nokogiri"'
  end
  has_nokogiri = true
rescue LoadError =>  e
  if ! has_nokogiri
    if $DEBUG
      STDERR.printf 'Exception: %s', message
    end
    $stderr.puts 'needed gem not found: nokogiri'
    exit 1
  end
end
# TODO: clear
has_restclient = false
begin
  require 'restclient'
  if $DEBUG
    puts 'Loading "restclient"'
  end
  has_restlient = true
rescue LoadError =>  e
  if ! has_restlient
    if $DEBUG
      STDERR.printf('Exception: %70.68s', e.message)
    end
    $stderr.puts 'needed gem not found: restclient'
  end
end

uri = URI('https://www.slimjet.com/chrome/google-chrome-old-version.php')
req = Net::HTTP::Get.new(uri.path)
downloads = {}
res = Net::HTTP.start(
  uri.host, uri.port,
  :use_ssl => uri.scheme == 'https',
  :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |https|
  res = https.request(req)
  if res.code.to_s == '200'
    input = res.body
    if $DEBUG
      STDERR.puts input
    end
    # NOTE: cannot use xml tools: a big number of HTML parser error
    begin
      document = Nokogiri::HTML(input)
      document.search('a[href *= "download-chrome.php"][href *= ".deb"]').each do |row|
        if $VERBOSE
          $stderr.puts ('in row: ' + row)  
        end   
        # release 69+ download url format change
        # from download-chrome.php?file=lnx%2Fchrome64_*.deb
        # to files%2F*%2Fgoogle-chrome-stable_current_amd64.deb
        # therefore need to keep both text and url
        # $stderr.puts row.attributes["href"]
        link = row.attributes['href'].to_s
        if (link.include?('chrome64_') || link.include?('_amd64'))
          version = row.text.strip
          downloads[version] = link.gsub(Regexp.new(Regexp.escape('download-chrome.php?file=')),'').gsub(/%2F/,'/')
          if $VERBOSE
            STDERR.puts version
            STDERR.puts downloads[version]
          end
        end
      end
    rescue => e
      if $DEBUG
        STDERR.printf 'Exception (ignored): %80s', e.message
      end
    end
  end
end
if $VERBOSE
  PP.pp downloads, $stderr
end
if $RELEASE.nil?
  # TODO:
  # puts downloads.sort_by(&:key).first

  last_download = (downloads.sort_by {|build, url| build}).last
  # no longer a hash
  pp [last_download[0], "#{$BASE_DOWNLOAD}/#{last_download[1]}"]
else
  selected_build = downloads.keys.find {|build| build =~ /^#{$RELEASE}.*/i}
  if selected_build.nil?
    puts "The specific release #{$RELEASE} is not available on https://www.slimjet.com/chrome/google-chrome-old-version.php"
  else
    pp [selected_build,"#{$BASE_DOWNLOAD}/#{downloads[selected_build]}"]
  end
end

