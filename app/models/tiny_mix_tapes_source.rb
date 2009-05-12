class TinyMixTapesSource < Source

  XML_FEED_URL = "http://tinymixtapes.com/spip.php?page=backend"

  def self.get_host()
    "http://www.tinymixtapes.com/"
  end

  def self.scrape()
    Log::log(nil, nil, Log::SCRAPE, nil, "Starting a #{TinyMixTapesSource.to_s} scrape.")
    source = Source::get(Source::TINY_MIX_TAPES_SOURCE)
    feed_xml = get_xml_feed(XML_FEED_URL)
  
    artist_names_and_urls = get_artist_names_and_urls_from_feed_xml(feed_xml)
    i = add_artists_and_link(artist_names_and_urls, source)
    Log::log(nil, nil, Log::SCRAPE, nil, "Finishing a #{TinyMixTapesSource.to_s} scrape. #{i} artists added.")
    
    i
  end
  
  # extracts music review feed items and then pulls out artist name and url for review
  def self.get_artist_names_and_urls_from_feed_xml(feed_xml)
    artist_names_and_urls = {}
    feed_xml.elements.each('rss/channel/item') do |item_xml|
      description = item_xml.elements["description"].text
      if description.scan(/MUSIC REVIEWS/).length > 0 # is a music review
        artist_name = item_xml.elements["title"].text
        url = item_xml.elements["link"].text
        artist_names_and_urls[artist_name] = url
      end
    end
    
    artist_names_and_urls
  end
  
  def self.add_artists_and_link(artist_names_and_urls, source)
    i = 0
    http = get_http_connection(get_host())
    for artist_name in artist_names_and_urls.keys()
      review_url = artist_names_and_urls[artist_name]
      article_text = get_page_content(http, review_url, nil)
      other_artist_names = get_others(article_text)

      main_artist_name = Util::scrub_fastidious_entities(artist_name)
      if main_artist_name && main_artist_name != ""
        main_artist = Artist.get_or_create(main_artist_name)
        if main_artist.save()
          i += 1
          for other_artist_name in other_artist_names # create other artist and link w/ main artist and save both            
            other_artist_name = Util::scrub_fastidious_entities(other_artist_name)
            if other_artist_name && other_artist_name != ""
              other_artist = Artist.get_or_create(other_artist_name)
              if other_artist.save()
                i += 1
                Link::get_or_create(main_artist, other_artist, source).save() # create/get link and save
              end
            end
          end
        end
      end
    end
    
    i
  end
  
  def self.get_others(review_text)
    others_plus_surround = review_text.match(/Others:<\/strong>[^<]*/).to_s
    others_raw = others_plus_surround.gsub(/Others:<\/strong>([^<]*)/, '\1')
    others = others_raw.split(", ")
  end
  
  def self.scrape_archive()
    music_reviews_for_a_letter_no_letter_url = "http://tinymixtapes.com/index.php?page=reviewarchive&fl="
    http = get_http_connection(get_host())
    source = Source::get(Source::TINY_MIX_TAPES_SOURCE)
    
    artist_names_and_urls = {}
    for letter in 'A'..'Z'
      music_reviews_for_a_letter_url = music_reviews_for_a_letter_no_letter_url + letter
      article_text = get_page_content(http, music_reviews_for_a_letter_url, nil)
      artist_names_and_urls = artist_names_and_urls.merge(get_artist_names_and_urls(article_text))
    end
  
    for artist_name in artist_names_and_urls.keys()
      if !TempArtistAssociation.already_saved?(artist_name, source)
        review_url = get_host() + artist_names_and_urls[artist_name]
        article_text = get_page_content(http, review_url, nil)
        others = get_others(article_text)
        TempArtistAssociation::new_from_associating(artist_name, others.join(", "), source).save()
      end
    end
  end

  def self.get_artist_names_and_urls(article_text)
    article_artist_names_and_urls = {}
    artist_names_and_urls_raw = article_text.scan(/<td><a href=[^>]*>[^<]*<\/a><\/td>/)
    for artist_name_and_url_raw in artist_names_and_urls_raw
      artist_name_and_url_raw = artist_name_and_url_raw.gsub(/<td>/, "").gsub(/<\/td>/, "") # remove tds
      artist_name = artist_name_and_url_raw.gsub(/<a href=[^>]*>([^<]*)<\/a>/, '\1')
      url = artist_name_and_url_raw.gsub(/<a href="([^>]*)">[^<]*<\/a>/, '\1')
      
      article_artist_names_and_urls[artist_name] = url # save away
    end
    
    article_artist_names_and_urls
  end
end