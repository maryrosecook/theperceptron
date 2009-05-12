require 'digest/md5'

module Daylifeing
  
  BASE_URL = "http://freeapi.daylife.com/xmlrest/publicapi/4.2/search_getRelatedArticles?accesskey=#{Configuring.get('daylifeing_access_key')}"
  #&query=Condoleezza+Iraq
  
  def self.search(query, date)
    items = []
    url =  BASE_URL
    url += "&signature=" + get_signature(query)
    url += "&query=" + query
    url += "&end_time=" + date.to_date.strftime("%Y-%m")
    
    xml = APIUtil.response_to_xml(APIUtil.get_request(url))
    
    xml.elements.each("response/payload/article") do |data|
      item = {}
      item[:title] = data.elements["headline"].text if data.elements["headline"]
      item[:url] = data.elements["url"].text if data.elements["url"]
      item[:source] = data.elements["source/name"].text if data.elements["source/name"]
      items << item
      break if items.length > 2
    end

    return items
  end
  
  def self.get_signature(query)
    return Digest::MD5.hexdigest(Configuring.get('daylifeing_access_key') + Configuring.get('daylifeing_shared_secret') + query)
  end
end