class WikipediaLabelSource < Source

  def self.update()
    Log::log(current_user, nil, Log::SCRAPE, nil, "Starting a #{WikipediaLabelSource.to_s} scrape.")
    source = Source::get(Source::WIKIPEDIA_LABEL_SOURCE)
    
    i = 0
    labels_and_artists = Wikipediaing::get_label_artists()
    for label_title in labels_and_artists.keys().sort {|x,y| x <=> y }
      Logger.new(STDOUT).error(label_title)
      label_artist_titles = labels_and_artists[label_title]
      
      # save and get list of all aritsts on this label
      label_artists = []
      for label_artist_title in label_artist_titles
        label_artist_name = Wikipediaing::title_to_name(label_artist_title)
        label_artist = Artist.get_or_create(label_artist_name)
        i += 1 if label_artist.new_record?()
        if label_artist.save()
          label_artists << label_artist
        end
      end
      
      # create links between artists
      for artist_1 in label_artists
        for artist_2 in label_artists
          if artist_1.id != artist_2.id
            Link::get_or_create(artist_1, artist_2, source).save() # create/get link, add source and save
          end
        end
      end
    end
    
    Log::log(current_user, nil, Log::SCRAPE, nil, "Finishing a #{WikipediaLabelSource.to_s} scrape.")
    
    i
  end
end