class EpitonicSimilarSource < Source

  def self.get_starting_artist(exclude_artists)
    Source::get_starting_artist(Source::get(Source::EPITONIC_SIMILAR_SOURCE), exclude_artists)
  end
  
  def self.get_host()
    "http://epitonic.com/"
  end

  def self.spider(parent_artist, http)
    page_content = get_page_content(http, parent_artist.path, nil)
    similar_artists_raw = Source::get_content_section(page_content, "Similar Artists: ", "Other Suggestions")
    similar_artists_and_links = EpitonicSourceLib::extract_artists_and_links(similar_artists_raw, ",")
    add_artists_and_links(parent_artist, similar_artists_and_links, Source::get(Source::EPITONIC_SIMILAR_SOURCE), Source::NO_RETRACE, Source::PATH_IS_NOT_WEBSITE)
  end
end