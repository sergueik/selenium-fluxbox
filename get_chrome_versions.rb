require 'uri'
require 'net/https'
require 'pp'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: example.rb [options]'
  opts.on('-v', '--[no-]verbose', 'Run verbosely') do |v|
    options[:verbose] = v
  end
  opts.on('-rRELEASE', '--run=RELEASE', 'Return the build number of available RELEASE chrome') do |data|
    options[:version] = data
  end
end.parse!

$DEBUG = options[:debug]
$RELEASE = options[:version]
$VERBOSE = options[:verbose]
$BASE_DOWNLOAD='http://www.slimjetbrowser.com/chrome'

# optionally when there is gem, use it
# https://airbrake.io/blog/ruby-exception-handling/loaderror
has_nokogiri = false
begin
  require 'nokogiri'
  puts 'Loading "nokogiri"'
  has_nokogiri = true
rescue LoadError =>  e
  if ! has_nokogiri
    if $DEBUG
      STDERR.printf 'Exception (ignored): %s', message
    end
  end
end
# TODO: clear
has_restclient = false
begin
  require 'restclient'
  puts 'Loading "restclient"'
  has_restlient = true
rescue LoadError =>  e
  if ! has_restlient
    if $DEBUG
      # TODO:
      # message = sprintf('Exception (ignored): %s', e.message)
      STDERR.printf('Exception (ignored): %70.68s', e.message)
    end
  end
end
pp "Loaded nokogiri: #{has_nokogiri}"
pp "Loaded restclient: #{has_restclient}"


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
    if $VERBOSE
      STDERR.puts input
    end
    begin
      document = Nokogiri::HTML(input)
      document.search('a[href *= "download-chrome.php"][href *= ".deb"]').each do |row|
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
  pp downloads
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

