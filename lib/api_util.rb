module APIUtil
  
  TIMEOUT_OK = true
  TIMEOUT_NOT_OK = false
  
  # gets xml from passed url
  def self.get_request(url)
    response = nil
    url = make_url_safe(url)
    begin
      Timeout::timeout(3) do
        resp = Net::HTTP.get_response(URI.parse(url)) # get_response takes an URI object
        response = resp.body
      end
    rescue Timeout::Error
      Log::log(nil, nil, Log::API_TIMEOUT, nil, "URL: #{url}")
    rescue
      Log::log(nil, nil, Log::API_UNKNOWN_FAIL, nil, "URL: #{url}")
    end
  
    response
  end
  
  # checks that requested resource exists
  def self.url_ok?(url, timeout, timeout_ok)
    fine = false
    begin
      Timeout::timeout(timeout) do
        resp = Net::HTTP.get_response(URI.parse(make_url_safe(url))) # get_response takes an URI object
        fine = true if resp.code != "404"
      end
    rescue Timeout::Error 
      fine = true if timeout_ok # success cause could be big resource on the other end
    rescue # let through other errors
    end
  
    fine
  end
  
  def self.safely_parse_url(url)
    parsed_url = nil
    safer_url = APIUtil::make_url_safe(url)
    begin
      parsed_url = URI::parse(safer_url)
    rescue # failure
    end
    
    parsed_url
  end
  
  def self.response_to_xml(body)
    xml = REXML::Document.new(body)
  end

  def self.simple_extract_tag_data(res, tag)
    tag_data = nil
    if res
      if xmlDoc = response_to_xml(res)
        if xmlDoc.elements[tag]
          tag_data = xmlDoc.elements[tag].text
        end
      end
    end
    
    tag_data
  end
  
  def self.simple_extract_tag_datas(res, subs, tag)
    items = []
    if res
      if xmlDoc = response_to_xml(res)
        xmlDoc.elements.each(subs) do |item|
          items << item.elements[tag].text
        end
      end
    end

    items
  end

  def self.escape_str_for_regexp(str)
    str.gsub(/\(/, "\\(").gsub(/\)/, "\\)").gsub(/\./, "\\.").gsub(/\*/, "\\*").gsub(/\+/, "\\+").gsub(/\?/, "\\?").gsub(/\{/, "\\{").gsub(/\}/, "\\}").gsub(/\[/, "\\[").gsub(/\]/, "\\]")
  end
  
  def self.make_url_safe(url)
    url.strip.gsub(/\s/, "%20")
  end
end