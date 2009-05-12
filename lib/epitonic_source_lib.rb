module EpitonicSourceLib
  
  # extracts artist names and links to their pages from raw artist list string
  def self.extract_artists_and_links(artists_raw, delim)
    artists_and_links = {}
    for artist_and_link_raw in artists_raw.split(delim)
      if artist_and_link_raw =~ /<a/
        potential_link = Util::strip_html(artist_and_link_raw.sub(/<a href="(.*)" objectId=".*">.*<\/a>/, '\1')).strip
        begin
          URI.parse(potential_link)
          link = potential_link # if get to here, url is OK
        rescue
          link = ""
        end
        artist = Util::strip_html(artist_and_link_raw.sub(/<a href=".*" objectId=".*">(.*)<\/a>/, '\1')).strip
      else # artist not linked to their page
        link = ""
        artist = Util::strip_html(artist_and_link_raw).strip
      end
      
      artists_and_links[artist] = link
    end
    
    artists_and_links
  end
end