require 'uri'
require 'net/https'
require 'nokogiri'

uri = URI('https://www.slimjet.com/chrome/google-chrome-old-version.php')
req = Net::HTTP::Get.new(uri.path)

res = Net::HTTP.start(
        uri.host, uri.port,
        :use_ssl => uri.scheme == 'https',
        :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |https|
  res = https.request(req)
  if res.code.to_s == '200'
    input = res.body	
    document = Nokogiri::HTML(input)
    document.search('a[href *= "download-chrome.php"][href *= ".deb"]').each do |row|
      # 69 and 70 - format change
      # from download-chrome.php?file=lnx%2Fchrome64_*.deb
      # to files%2F*%2Fgoogle-chrome-stable_current_amd64.deb
      # $stderr.puts row.attributes["href"]
      link = row.attributes['href'].to_s
      if (link.include?('chrome64_') || link.include?('_amd64'))
        puts row.text.strip
      end
    end
  end
end

