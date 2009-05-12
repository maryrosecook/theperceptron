module Twfying

  BASE_GET_DEBATES_URL = "http://www.theyworkforyou.com/api/getDebates?key=#{Configuring.get('twfy_api_key')}"

  DEFAULT_DEBATE = "commons"
  DEFAULT_OUTPUT = "xml"

  def self.search_debates(search, mp_name)
    statements = []
    if Util.ne(search)
      # get MP person id if MP specified
      mp = nil
      mp = Mp.find_by_name(mp_name) if Util.ne(mp_name)

      url = form_search_debates_command(search, DEFAULT_DEBATE, DEFAULT_OUTPUT, mp)
      if res = APIUtil.get_request(url)
        if xmlDoc = APIUtil.response_to_xml(res)
          xmlDoc.elements.each("twfy/rows/match") do |data|
            item = {}
            item[:date] = data.elements["hdate"].text
            item[:statement] = data.elements["body"].text
            item[:url] = data.elements["listurl"].text
            first_name = data.elements["speaker/first_name"]
            last_name = data.elements["speaker/last_name"]
            item[:mp] = ""
            item[:mp] += first_name.text + " " if first_name
            item[:mp] += last_name.text if last_name
            statements << item
            break if statements.length > 9
          end
        end
      end
    end
    
    return statements
  end
  
  def self.form_search_debates_command(search, type, output, mp)
    url = BASE_GET_DEBATES_URL
    url += "&search=" + APIUtil.make_url_safe(search)
    url += "&type=" + DEFAULT_DEBATE
    url += "&output=" + DEFAULT_OUTPUT
    url += "&person=" + mp.person_id.to_s if mp && Util.ne(mp.person_id)
    return url
  end
  
  def self.read_mp_xml()
    xml = nil
    File.open("public/mplist", "r") do |f|
      #raise f.read
      if xml = APIUtil.response_to_xml(f.read)
        xml.elements.each("twfy/match") do |data|
          Mp.new_from_xml(data.elements["person_id"].text, data.elements["name"].text).save()
        end
      end
    end
  end
end