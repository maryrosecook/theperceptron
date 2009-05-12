module WhereToLive
  
  MAX_TOP_ARTISTS = 30
  
  def self.get_artist_url(artist)
    APIUtil::simple_extract_tag_data(Lastfming::artist_get_info(artist), "lfm/artist/url")
  end
  
  def self.get_favourite_artists(username)
    favourite_artist_names = []
    top_artist_res = Lastfming::user_get_top_artists(username)
    top_artist_names = APIUtil::simple_extract_tag_datas(top_artist_res, "lfm/topartists/artist", "name")
    i = 0
    top_artist_names.each do |top_artist_name| 
      break if i > MAX_TOP_ARTISTS
      favourite_artist_names << top_artist_name if !favourite_artist_names.include?(top_artist_name)
      i += 1
    end

    #loved_tracks_res = Lastfming::user_get_loved_tracks(username)
    #loved_artist_names = APIUtil::simple_extract_tag_datas(loved_tracks_res, "lfm/lovedtracks/track", "artist/name")
    #loved_artist_names.each { |loved_artist_name| favourite_artist_names << loved_artist_name if !favourite_artist_names.include?(loved_artist_name) }
    
    favourite_artist_names
  end
  
  def self.get_artist_event_cities(artist_name)
    artist_events_res = Lastfming::artist_get_events(artist_name)
    cities = APIUtil::simple_extract_tag_datas(artist_events_res, "lfm/events/event", "venue/location/city")
  end
end