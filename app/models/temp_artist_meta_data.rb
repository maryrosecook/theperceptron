class TempArtistMetaData < ActiveRecord::Base
  belongs_to :artist

  def self.new_from_scraping(artist)
    temp_artist_meta_data = self.new()
    temp_artist_meta_data.article_title = Wikipediaing::pull_article_title(artist.id)
    temp_artist_meta_data.summary = Wikipediaing::pull_artist_summary(artist.id, temp_artist_meta_data.article_title)
    temp_artist_meta_data.myspace_url = Yahoo::get_artist_myspace_url(artist, 0) if !Util.ne(artist.myspace_url)
    temp_artist_meta_data.website = Wikipediaing::pull_website(artist.id, temp_artist_meta_data.article_title) if !Util.ne(artist.website)
    temp_artist_meta_data.added = 0
    temp_artist_meta_data.artist = artist
    
    temp_artist_meta_data
  end
  
  def self.gather_temp_artist_meta_datas(sleepytime, gather_in_one_go)
    for i in (0..gather_in_one_go)
      gathered = 0
      if artist = Artist.find(:first, :offset => Odd.get_data("last_updated_artist_offset"))
        temp_artist_meta_data = TempArtistMetaData.new_from_scraping(artist)
        temp_artist_meta_data.save()
        Logger.new(STDOUT).error artist.name.to_s if !Util.production?
        sleep(sleepytime)
        gathered = 1
      end
      Util::set_offset("last_updated_artist_offset", gathered, 1)
    end
    
    return gather_in_one_go
  end
  
  # adds and saves all non added temp_artist_association artists and links w/ others
  def self.convert_temp_artist_meta_datas()
    i = 0
    for temp_artist_meta_data in find_data_not_added()
      artist = temp_artist_meta_data.artist
      temp_artist_meta_data.update_artist() 
      i += 1
    end
        
    return i
  end
  
  def update_artist
    if self.artist
      self.artist.set_article_title(self.article_title)
      self.artist.set_summary(self.summary)
      self.artist.set_myspace_url(self.myspace_url) if Util.ne(self.myspace_url)
      self.artist.set_website(self.website) if Util.ne(self.website)
      self.artist.set_sample_track_url(self.sample_track_url) if Util.ne(self.sample_track_url)
      self.artist.save()
      self.added = 1
      self.save()
    end
  end
  
  def self.find_data_not_added()
    self.find(:all, :conditions => "added = 0")
  end
end