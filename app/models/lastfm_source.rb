class LastfmSource < Source

  NUM_ARTISTS_IN_ONE_GO = 1500

  def self.get_host()
    "http://www.last.fm/"
  end
  
  def self.scrape()
    http = get_http_connection(get_host())
    source = Source::get(Source::LASTFM_SOURCE)
    log = Logger.new(STDOUT)
    i = 0
    offset = Odd.get_data("last_lastfm_offset")
    for artist in Artist.find(:all, :offset => offset, :limit => NUM_ARTISTS_IN_ONE_GO)
      res = Lastfming::artist_get_similar(artist)
      similar_artist_names = extract_similar_artist_names(res)
      TempArtistAssociation::new_from_associating(artist.name, similar_artist_names.join(", "), source).save()
      log.error(i.to_s + " " + artist.name.to_s)
      i += 1
    end
    
    # set offset to start from next time
    (i + 1) < NUM_ARTISTS_IN_ONE_GO ? new_offset = 0 : new_offset = offset + NUM_ARTISTS_IN_ONE_GO
    Odd.set_data("last_lastfm_offset", new_offset)
    
    i
  end
  
  def self.extract_similar_artist_names(res)
    similar_artist_names = []
    i = 0
    if res
      if xmlDoc = REXML::Document.new(res)
        xmlDoc.elements.each("lfm/similarartists/artist") do |artist|
          similar_artist_names << artist.elements["name"].text
          i += 1
          break if i > 9
        end
      end
    end

    similar_artist_names
  end
end