class MuxtapeSource < Source

  def self.get_host()
    "http://www.muxtapestumbler.com/"
  end
  
  def self.scrape_archive()
    http = get_http_connection(get_host())
    source = Source::get(Source::MUXTAPE_SOURCE)
    
    connection_count = 0
    for artist in Artist.find(:all)
      if !TempArtistAssociation::already_saved?(artist.name, source) # not already done this one
        popular_others = []
        if connection_count == 50
          http = get_http_connection(get_host())
          connection_count = 0
        end
        for article_text in gather_article_texts(0, artist, http, []) # run through all results pages
          all_others = get_others(article_text, artist)
          for other_1 in all_others
            num = 0
            for other_2 in all_others
              num += 1 if other_1 == other_2
              if num > 1
                popular_others << other_1
                break
              end
            end
          end
        end
        
        popular_others = popular_others.uniq()
        Logger.new(STDOUT).error(artist.name + ": #{popular_others.length}")
        TempArtistAssociation::new_from_associating(artist.name, popular_others.join(", "), source).save()
        connection_count += 1
      end
    end
  end
  
  # gets all result articles for passed artist
  def self.gather_article_texts(page_num, artist, http, article_texts)
    Logger.new(STDOUT).error(" " + page_num.to_s)
    muxtapes_for_artist_url = get_host() + "search.php?page=#{page_num}&explicit=1&artist_search=#{Util::str_to_query(artist.name)}"
    article_text = get_page_content(http, muxtapes_for_artist_url, nil)
    article_texts << article_text # add article text to list 
    if article_text.match(/\<span class=\"info\"\>More\<\/span\>/) # if more link, continue
      gather_article_texts(page_num + 1, artist, http, article_texts)
    end
    
    article_texts
  end
  
  def self.get_others(article_text, artist)
    others = []
    raw_others = article_text.scan(/Search for\<\/span\>[^-]*- /)
    for raw_other in raw_others
      raw_other = raw_other.gsub(/Search for\<\/span\>/, "")
      other = raw_other.gsub(/- /, "").strip()
      others << other if other.downcase() != artist.name.downcase()
    end

    others
  end
  
  # <% for suspect in @suspect %>
  #   <a href='http://www.muxtapestumbler.com/search.php?page=0&explicit=0&artist_search=<%= suspect.name %>'><%= suspect.name %></a><br/>
  # 
  # <% end-%>
  # def self.data
  #   suspect = []
  #   all = TempArtistAssociation::find(:all, :conditions => "added = 0 && others IS NOT NULL && others != ''")
  #   Logger.new(STDOUT).error(all.length.to_s)
  #   num_in_range = 0
  #   for temp in all
  #      suspect << temp if [10,11,12].include?(temp.others.split(", ").length)
  #   end
  #   
  #   suspect
  #   
  #   suspect = []
  #   for temp in TempArtistAssociation::find(:all, :conditions => "added = 0 && others IS NOT NULL && others != ''")
  #     if temp.others.split(", ").length > 50
  #       suspect << temp
  #     end
  #   end
  #   suspect
  # end
end