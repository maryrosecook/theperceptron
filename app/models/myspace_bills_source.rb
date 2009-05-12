class MyspaceBillsSource < Source
  
  SHOW_LIST_BASE_URL = "/index.cfm?fuseaction=user.viewprofile&friendID="
  NUM_ARTISTS_IN_ONE_GO = 30
  
  def self.get_host()
    "http://profile.myspace.com/"
  end
  
  def self.scrape()
    http = get_http_connection(get_host())
    source = Source::get(Source::MYSPACE_BILLS_SOURCE)
    
    i = 0
    offset = Odd.get_data("last_myspace_bills_offset")
    for artist in Artist.find(:all, :offset => offset, :limit => NUM_ARTISTS_IN_ONE_GO)
      if artist.get_myspace_url() != ""
        page_content = get_page_content(http, artist.get_myspace_url(), 8)
        add_shows(artist, source, page_content)
      end
      i += 1
    end
    
    # set offset to start from next time
    (i + 1) < NUM_ARTISTS_IN_ONE_GO ? new_offset = 0 : new_offset = offset + NUM_ARTISTS_IN_ONE_GO
    Odd.set_data("last_myspace_bills_offset", new_offset)
  end
  
  def self.scrape_paths()
    http = get_http_connection(get_host())
    source = Source::get(Source::MYSPACE_BILLS_SOURCE)
    for artist in Artist.find(:all, :conditions => "path like \"%fuseaction%\"")
      add_shows(artist, source, get_page_content(http, artist.path, 1))
    end
  end
  
  def self.add_shows(artist, source, page_content)
    gigs_section_raw = Source::get_content_section(page_content, "Upcoming Shows", "Latest Blog Entry")
    for with in gigs_section_raw.scan(/w\/[^<]*/) # pull out w/ sections
      with = with.gsub(/w\//, "") # remove w/
      TempArtistAssociation::new_from_associating(artist.name, with, source).save() if reliable?(with)
    end
  end
  
  def self.reliable?(w)
    a = w.match(/and/i)
    b = w.match(/@/)
    c = w.match(/\&/)
    d = w.match(/\+/)
    e = w.match(/\//)
    f = w.match(/\|/)
    g = w.match(/\)/)
    h = w.match(/ft/i)
    i = w.match(/feat/i)
    j = w.match(/tba/i)
    k = w.match(/\?/)
    
    !a && !b && !c && !d && !e && !f && !g && !h && !i && !j && !k
  end
end