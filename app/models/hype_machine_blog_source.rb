class HypeMachineBlogSource < Source

  DELICIOUS_FEED_USERNAME = "taggedhype"
  DELICIOUS_FEED_COUNT = 100

  def self.scrape()
    Log::log(nil, nil, Log::SCRAPE, nil, "Starting a #{HypeMachineBlogSource.to_s} scrape.")
    source = Source::get(Source::HYPE_MACHINE_BLOG_SOURCE)
    feed_xml = Deliciousing::get_user_rss_feed(DELICIOUS_FEED_USERNAME, DELICIOUS_FEED_COUNT)

    blogs_and_artist_names = get_blogs_and_artist_names_from_feed_xml(feed_xml)
    i = add_artists_and_link(blogs_and_artist_names, source)
    Log::log(nil, nil, Log::SCRAPE, nil, "Finishing a #{HypeMachineBlogSource.to_s} scrape. #{i} artists added.")
    
    i
  end
  
  # returns a hash of blogs pointing to arrays of artists
  def self.get_blogs_and_artist_names_from_feed_xml(feed_xml)
    blogs_and_artist_names = {}
    feed_xml.elements.each('rss/channel/item') do |item_xml|
      blog_url = nil
      artist = nil
      artist_name_and_song_raw = item_xml.elements["title"].text
      blog_url_raw = item_xml.elements["description"].text
      
      if blog_url_raw = blog_url_raw.match(/from:(.*)/).to_s
        blog_url = blog_url_raw.gsub(/from:/, "").strip()
        if blog_url && blog_url != "" # got blog_url so try and get artist
          if artist_name_raw = artist_name_and_song_raw.match(/.* -/).to_s # split by dash
            artist_name = artist_name_raw.gsub(/-/, "").strip() # remove dash and whitespace
            
            if artist_name && artist_name != "" # got artist so put them in hash
              if blogs_and_artist_names[blog_url]
                blogs_and_artist_names[blog_url] << artist_name
              else
                blogs_and_artist_names[blog_url] = [artist_name]
              end
            end
          end
        end
      end
    end
    
    blogs_and_artist_names
  end
  
  def self.add_artists_and_link(blogs_and_artist_names, source)
    i = 0
    for blog_url in blogs_and_artist_names.keys().sort {|x,y| x <=> y }
      Logger.new(STDOUT).error(blog_url)
      blog_artist_names = blogs_and_artist_names[blog_url]
      
      sub_source = SubSource::get_or_create(blog_url, source) # create a sub source for this blog
      
      # save and get list of all aritsts from this blog
      new_blog_artists = []
      for blog_artist_name in blog_artist_names
        blog_artist = Artist.get_or_create(blog_artist_name)
        blog_artist.sub_sources() << sub_source # add blog sub source to artist
        i += 1 unless blog_artist.id
        if blog_artist.save()
          new_blog_artists << blog_artist
        end
      end
      
      # create array of new and old artists with this blog_url subsource
      existing_blog_url_artists = sub_source.artists()
      blog_artists_existing_and_new = new_blog_artists + existing_blog_url_artists
      
      # create links between artists in this scrape
      for artist_1 in new_blog_artists
        for artist_2 in blog_artists_existing_and_new
          if artist_1.id != artist_2.id
            Link::get_or_create(artist_1, artist_2, source).save() # create/get link, add source and save
          end
        end
      end
    end
    
    i
  end
  
end