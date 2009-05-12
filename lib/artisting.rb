module Artisting
  
  NUM_SAMPLE_TRACK_URL_CHECKS_IN_ONE_GO = 60
  NUM_ARTISTS_IN_ONE_GO = 25
  
  # updates a batch of artists
  def self.update_artist_details()    
    num_gathered = TempArtistMetaData.gather_temp_artist_meta_datas(1, NUM_ARTISTS_IN_ONE_GO)
    TempArtistMetaData.convert_temp_artist_meta_datas()
    Log::log(nil, nil, Log::EVENT, nil, "Finishing update_artist_details().  #{num_gathered} artists updated.")
    return num_gathered
  end

  def self.remove(artist)
    success = true
    for link in artist.links()
      link.link_ratings().each {|link_rating| success = false unless link_rating.destroy() }
      link.sources().clear()
      link.users().clear()
      success = false unless link.destroy()
    end
    
    artist.sub_sources().each {|sub_source| success = false unless sub_source.destroy() }
    artist.flags().each {|flag| success = false unless flag.destroy() }
    artist.rated_artists().each {|rated_artist| success = false unless rated_artist.destroy() }
    artist.rejections().each {|rejection| success = false unless rejection.destroy() }
    Recommendation.get_where_artist_sought_or_recommended(artist).each {|recommendation| success = false unless recommendation.destroy() }
    for search in Search.find(:all, :conditions => "search_artist_id = #{artist.id}")
      success = false unless search.destroy()
    end
    
    success = false unless artist.destroy()
    
    success
  end
  
  def self.merge(artist_1, artist_2)
    success = true
    for link in artist_2.links()
      link.first_artist = artist_1 if link.first_artist == artist_2
      link.second_artist = artist_1 if link.second_artist == artist_2
      link.save()
    end
    
    for sub_source in artist_2.sub_sources()
      sub_source.artists().delete(artist_2)
      sub_source.artists() << artist_1 unless sub_source.artists().include?(artist_1)
      success = false unless sub_source.save()
    end
    
    for flag in artist_2.flags()
      flag.artist = artist_1
      success = false unless flag.save()
    end
    
    for rated_artist in artist_2.rated_artists()
      rated_artist.artist = artist_1
      success = false unless rated_artist.save()
    end
    
    # no rejections - keep all artist-specific data the same
    
    for recommendation in Recommendation.get_where_artist_sought_or_recommended(artist_2)
      if recommendation.search_artist == artist_2
        new_rec = Recommendation.get_or_create(recommendation.user, artist_1, recommendation.recommended_artist)
      elsif recommendation.recommended_artist == artist_2
        new_rec = Recommendation.get_or_create(recommendation.user, recommendation.search_artist, artist_1)
      end
      
      if new_rec
        new_rec.saved = 1 if recommendation.saved == 1 # only change if old rec definitely saved
        success = false unless new_rec.save()
      end
      success = false unless recommendation.destroy()
    end
    
    for search in Search.find(:all, :conditions => "search_artist_id = #{artist_2.id}")
      search.search_artist = artist_1
      success = false unless search.save()
    end
    
    success = false unless artist_2.destroy()
    
    success
  end

  
  def self.delete_bad_myspace_urls()
    i = 0
    for artist in Artist.find(:all)
      myspace_url = artist.get_myspace_url()
      if myspace_url != ""
        altered = false
        if myspace_url.match(/ /) # not rescuable
          artist.myspace_url = nil
          altered = true
        elsif myspace_url.match(/\|/) # rescue
          artist.myspace_url = artist.myspace_url.gsub(/([^|]*).*/, '\1')
          altered = true
        elsif myspace_url.match(/\]/) # rescue
          artist.myspace_url = artist.myspace_url.gsub(/\]/, '')
          altered = true
        end
        
        if altered
          artist.save()
          i += 1
        end
      end
    end
    
    i
  end
  
  def self.delete_bad_sample_track_urls()
    i = 0
    log = Logger.new(STDOUT)
    offset = Odd.get_data("last_delete_bad_sample_track_urls_offset")
    
    for artist in Artist.find(:all, :offset => offset, :limit => NUM_SAMPLE_TRACK_URL_CHECKS_IN_ONE_GO,
                              :conditions => "sample_track_url IS NOT NULL && sample_track_url != ''", :order => 'id')
      if Seeqpodding::track_ok?(artist.sample_track_url)
        log.error(artist.id.to_s)
      else
        log.error("not fine:" + artist.sample_track_url)
        artist.sample_track_url = nil
        artist.save()
      end
      
      i += 1
    end
    
    Util::set_offset("last_delete_bad_sample_track_urls_offset", i, NUM_SAMPLE_TRACK_URL_CHECKS_IN_ONE_GO)

    i
  end
  
  def self.get_random_artists(num)
    random_artists = []
    total_artists = Artist.count(:all)
    (0..num - 1).each{|i| random_artists << Artist.find(:first, :offset => rand(total_artists)) }
    
    random_artists
  end
end