class AbsolutePunkSource < Source

  XML_FEED_URL = "http://www.absolutepunk.net/external.php?type=rss2&forumids=166"

  def self.get_host()
    "http://www.absolutepunk.net/"
  end

  def self.scrape()
    Log::log(nil, nil, Log::SCRAPE, nil, "Starting a #{AbsolutePunkSource.to_s} scrape.")
    source = Source::get(Source::ABSOLUTE_PUNK_SOURCE)
    feed_xml = get_xml_feed(XML_FEED_URL)
  
    artist_names_and_urls = get_artist_names_and_urls_from_feed_xml(feed_xml)
    i = add_temp_artist_associations(artist_names_and_urls, source)
    Log::log(nil, nil, Log::SCRAPE, nil, "Finishing an #{AbsolutePunkSource.to_s} scrape. #{i} artists added.")

    i
  end
  
  # extracts music review feed items and then pulls out artist name and url for review
  def self.get_artist_names_and_urls_from_feed_xml(feed_xml)
    artist_names_and_urls = {}
    feed_xml.elements.each('rss/channel/item') do |item_xml|
      artist_name = item_xml.elements["title"].text.gsub(/([^-]*) -.*/, '\1')
      url = item_xml.elements["link"].text
      artist_names_and_urls[artist_name] = url
    end

    artist_names_and_urls
  end
  
  def self.add_temp_artist_associations(artist_names_and_urls, source)
    i = 0
    http = get_http_connection(get_host())
    for artist_name in artist_names_and_urls.keys()
      if !TempArtistAssociation.already_saved?(artist_name, source)
        review_url = artist_names_and_urls[artist_name]
        article_text = get_page_content(http, review_url, nil)
        if others = get_others(article_text)
          TempArtistAssociation::new_from_associating(artist_name, others.join(", "), source).save()
          i += 1
        end
                  Logger.new(STDOUT).error(artist_name)
      end
    end

    i
  end
  
  def self.get_others(review_text)
    others = nil
    others_raw = get_content_section(review_text, "<legend>Recommended if you like:</legend>", "</fieldset>")
    if others_raw && others_raw != "" && !others_raw.match(/<i>/) # got some hopefully not too weird others
      others = others_raw.split(", ")
    end
    
    others
  end
end