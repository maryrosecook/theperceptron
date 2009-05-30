module Seeqpodding
  
  def get_host()
    "http://www.seeqpod.com/"
  end
  
  def self.pull_sample_track_url(artist_id)
    sample_track_url = nil
    artist = Artist.find(artist_id)
    api_uid = Util::rand_el(Configuring.get("seeqpod_api_uids"))
    escaped_artist_name = URI.escape(artist.name, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
    res = get_call("http://www.seeqpod.com/api/v0.2/#{api_uid}/music/search/#{escaped_artist_name}")
    sample_track_url = extract_valid_file_url_from_results(res, artist)
    artist.set_sample_track_url(sample_track_url)
    artist.save()
    
    sample_track_url
  end
  
  def self.extract_valid_file_url_from_results(res, artist)
    url = ""
    if res
      if xmlDoc = REXML::Document.new(res.body)
        xmlDoc.elements.each("playlist/trackList/track") do |track|
          track_url = track.elements["location"].text
          if !Rejection.rejected?(artist, Artist::SAMPLE_TRACK_URL, track_url)
            track_creator = track.elements["creator"].text
            escaped_artist_name = APIUtil.escape_str_for_regexp(artist.name)

            if track_creator && track_creator.match(escaped_artist_name) # if creator seems like band name and get nil response (file there) then use this url result
              if track_ok?(track_url) # test for response
                url = track_url
                break
              end
            end
          end
        end
      end
    end

    url
  end
  
  # returns true if actual track doesn't 404 and get timely response from root of server
  def self.track_ok?(url)
    ok = false
    if parsed_url = APIUtil::safely_parse_url(url)
      host = "http://" + parsed_url.host
      ok = true if APIUtil.url_ok?(host, 5, APIUtil::TIMEOUT_NOT_OK) && APIUtil.url_ok?(url, 1, APIUtil::TIMEOUT_OK)
    end
    
    ok
  end
  
  def self.get_call(url_str)
    res = nil
    
    bad_url = false
    begin
      url = URI.parse(url_str)
    rescue
      bad_url = true
    end
    
    if !bad_url
      req = Net::HTTP::Get.new(url.path)
      begin  
        Timeout::timeout(10, Timeout::Error) do
          res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
        end
        #sleep(5)
      rescue Timeout::Error
      rescue
      end
    else
      res = -1
    end
    
    res
  end
end