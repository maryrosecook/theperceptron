['hpricot', 'cgi', 'open-uri'].each {|f| require f}
require 'uri'

module Deliciousing
  
  # returns rss feed of latest links for passed delicious user
  def self.get_user_rss_feed(username, num_records)
    xml = ""
    safe_url_str = "http://feeds.delicious.com/v2/rss/#{username}?count=#{num_records}"
    begin
      Timeout::timeout(10, Timeout::Error) do 
        if xml_str = Hpricot.XML(open(safe_url_str)).to_s
          xml = APIUtil::response_to_xml(xml_str) if xml_str && xml_str != ""
        end
      end
    rescue Timeout::Error
    end
    
    xml
  end
end