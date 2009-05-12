module Lastfming
  
  BASE_GET_ARTIST_GET_SIMILAR_URL = "http://ws.audioscrobbler.com/2.0/?method=artist.getsimilar&api_key=#{Configuring.get("last_fm_api_key")}&artist="
  BASE_GET_USER_TOP_ARTISTS_URL = "http://ws.audioscrobbler.com/2.0/?method=user.gettopartists&api_key=#{Configuring.get("last_fm_api_key")}&user="
  BASE_ARTIST_GET_EVENTS_URL = "http://ws.audioscrobbler.com/2.0/?method=artist.getevents&api_key=#{Configuring.get("last_fm_api_key")}&artist="
  BASE_GET_ARTIST_INFO_URL = "http://ws.audioscrobbler.com/2.0/?method=artist.getinfo&api_key=#{Configuring.get("last_fm_api_key")}&artist="
  BASE_USER_GET_LOVED_TRACKS = "http://ws.audioscrobbler.com/2.0/?method=user.getlovedtracks&api_key=#{Configuring.get("last_fm_api_key")}&user="

  def self.artist_get_similar(artist)
    url = BASE_GET_ARTIST_GET_SIMILAR_URL + artist.name
    APIUtil::get_request(url)
  end
  
  def self.user_get_top_artists(username)
    APIUtil::get_request(BASE_GET_USER_TOP_ARTISTS_URL + username)
  end
  
  def self.artist_get_events(artist)
    APIUtil::get_request(BASE_ARTIST_GET_EVENTS_URL + artist)
  end
  
  def self.artist_get_info(artist)
    APIUtil::get_request(BASE_GET_ARTIST_INFO_URL + artist)
  end
  
  def self.user_get_loved_tracks(username)
    APIUtil::get_request(BASE_USER_GET_LOVED_TRACKS + username)
  end
end