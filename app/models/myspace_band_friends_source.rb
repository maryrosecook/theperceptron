require 'htmlentities'

class MyspaceBandFriendsSource < Source

  def self.get_starting_artist(exclude_artists)
    Source::get_starting_artist(Source::get(Source::MYSPACE_BAND_FRIENDS_SOURCE), exclude_artists)
  end

  def self.get_host()
    "http://profile.myspace.com/"
  end

  def self.spider(parent_artist, http)    
    page_content = get_page_content(http, parent_artist.path, nil)
    friends_section_raw = Source::get_content_section(page_content, "Friend Space", "View All of")
    friend_names_and_links = extract_friend_names_and_links(friends_section_raw)
    artist_names_and_links = extract_artist_names_and_links_from_friends(friend_names_and_links, http)

    add_artists_and_links(parent_artist, artist_names_and_links, Source::get(Source::MYSPACE_BAND_FRIENDS_SOURCE), Source::NO_RETRACE, Source::PATH_IS_WEBSITE)
  end
  
  def self.extract_artist_names_and_links_from_friends(friend_names_and_links, http)
    artist_names_and_links = {}
    for friend_name in friend_names_and_links.keys()
      friend_page_content = get_page_content(http, friend_names_and_links[friend_name], nil)
      if Myspacing::is_band_page?(friend_page_content)
        artist_names_and_links[friend_name] = friend_names_and_links[friend_name]
      end
    end
    
    artist_names_and_links
  end
  
  # extracts and returns friends section of Myspace page
  def self.extract_friend_names_and_links(friends_section_raw)
    friend_names_and_links = {}
    urls_and_contents = friends_section_raw.scan(/<a[^<>]*>[^<>]*<\/a>/)
    for url_and_content in urls_and_contents
      link_raw = url_and_content.match(/href="[^"]*"/).to_s
      link_raw = link_raw.gsub(/href=/, "")
      link = link_raw.gsub(/"/, "")
      parsed_link = URI.parse(link)
      link_path_and_query = parsed_link.path + "?" + parsed_link.query
      
      friend_name_raw = url_and_content.match(/>.*</).to_s
      friend_name_raw = friend_name_raw.gsub(/>/, "")
      friend_name = friend_name_raw.gsub(/</, "")
      friend_name = friend_name.gsub(/\(.*\)/, "") # remove anything in parentheses
      friend_name = friend_name.gsub(/\[.*\]/, "") # remove anything in square brackets
      friend_name = friend_name.strip()
      friend_name = HTMLEntities.new().decode(friend_name) # convert html entities to their real chars

      friend_names_and_links[friend_name] = link_path_and_query if Myspacing::is_band_name?(friend_name)
    end

    friend_names_and_links
  end
end