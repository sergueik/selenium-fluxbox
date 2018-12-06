require 'uri'
require 'net/https'
require 'pp'
require 'nokogiri'

$DEBUG = false
$VERBOSE = false

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
    begin
      document = Nokogiri::HTML(input)
      document.search('a[href *= "download-chrome.php"][href *= ".deb"]').each do |row|
        # 69 and 70 - download url format change
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
pp downloads
last_download = (downloads.sort_by {|version, url| version}).last
pp last_download

#
# puts downloads.sort_by(&:key).first
