['hpricot', 'cgi', 'open-uri'].each {|f| require f}
require 'uri'

module Wikipediaing
  BAND_SECTION_HEADERS = ["Bands", "Past Bands", "Artists", "Current bands", "Former bands", "Roster", "Current Artists", "Former Artists", "Current roster", "Current Line-Up", "Notable artists", "artists", "bands", "Bands and artists", "Active Roster", "Inactive Roster", "Artists on", "Artist List"]

  TITLE_ADDITIONS = ["_(band)", "", "_(musician)", "_(rapper)"]
  ALT_TITLE_ADDITIONS = [" (band)", " (musician)", "(band)", " (rapper)", " (Band)", " (music)"] # keep old title additions despite removal from above cause might still be in db

  MYSPACE_HOST = "http://www.myspace.com/"

  DISAMBIGUATION_STRS = ["may refer to", "redirects here", "For other uses", "can mean different things"]

  def self.get_host()
    "http://en.wikipedia.org/"
  end

  def self.pull_artist_summary(artist_id, possible_article_title)
    article_summary = nil
    if artist = Artist.find(artist_id)
      if Util.ne(possible_article_title)
        article_summary = pull_article(possible_article_title, 0)
    
        # chop out info box, wiki formatting and urls etc
        if article_summary
          article_summary = article_summary.gsub(/\n/, " ") # new lines
          article_summary = article_summary.gsub(/^(.*)'''(.*)'''\s/, "") # info box
          article_summary = article_summary.gsub(/==[^=]*==/, "") # section headers
          article_summary = article_summary.gsub(/'''/, "") # triple quotes
          article_summary = article_summary.gsub(/\{\{.*\}\}/, "") # any random {{blah}} blocks - prob citations
          article_summary = article_summary.gsub(/\[\[([^\]\|]*)\]\]/, '\1') # remove sq bracketed wiki tags where no alts
          article_summary = article_summary.gsub(/\[\[[^\|\]]*\|([^\]]*)\]\]/, '\1') # pull out wiki tags and put back primary text
          article_summary = article_summary.gsub(/http:\/\/[^+]*?\s/, "\s") # urls
        end
      end
    end
    
    article_summary
  end

  def self.pull_website(artist_id, possible_article_title)
    website = nil
    if artist = Artist.find(artist_id)
      if Util.ne(possible_article_title)
        regexps = [Regexp.new("\\*[^\\*]*official web site[^\\*]*\\*", Regexp::IGNORECASE),
                   Regexp.new("\\*[^\\*]*official website[^\\*]*\\*", Regexp::IGNORECASE),
                   Regexp.new("\\*[^\\*]*official site[^\\*]*\\*", Regexp::IGNORECASE)]
        article = pull_article(possible_article_title, 0)           
        website_raw = extract_string_from_string(article, regexps)
        url = extract_url_from_external_link(website_raw)
        website = url if Util.ne(url) && !Rejection.rejected?(artist, Artist::WEBSITE, url)
      end
    end
      
    website
  end

  def self.extract_string_from_string(string, regexps)
    extracted_string = ""
    for regexp in regexps
      match = string.match(regexp)
      if match && match.to_s && match.to_s != ""
        extracted_string = match.to_s
        break
      end
    end
    
    extracted_string
  end

  def self.extract_url_from_external_link(external_link)
    url = ""
    if external_link && external_link != ""
      external_link = external_link.match(/http:\/\/[\S]*/).to_s
      url = external_link.strip() if external_link && external_link != ""
    end

    url
  end

  # returns an appropriate Wikipeida article title for the passed article_id
  def self.pull_article_title(artist_id)
    title = ""
    artist = Artist.find(artist_id)
    for title_addition in TITLE_ADDITIONS
      test_title = artist.name + title_addition
      if !Rejection.rejected?(artist, Artist::ARTICLE_TITLE, test_title)
        article_summary = pull_article(test_title, nil)
        if Util.ne(article_summary) && !disambiguation_article?(article_summary) && about_a_band?(article_summary)
          title = test_title
          break
        end
      end
    end
    
    title
  end

  # returns Wikipedia article URL for passed artist_id
  def self.pull_article_url(artist_id)
    article_url = ""
    if artist = Artist.find(artist_id)
      article_title = pull_article_title(artist.id)
      article_url = compose_article_url(article_title)
    end
    
    article_url
  end
  
  def self.compose_article_url(article_title)
    article_url = ""
    if article_title && article_title != ""
      article_url = get_host() + "wiki/" + article_title
    end
    
    article_url
  end

  def self.pull_article(title, section_number)
    article_text = ""
    if title && title != ""
      section_str = ""
      section_str = "&rvsection=#{section_number}" if section_number
      
      escaped_title = URI.escape(title, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
      safe_url_str = "http://en.wikipedia.org/w/api.php?action=query&prop=revisions#{section_str}&titles=#{escaped_title}&rvprop=content&redirects&format=xml"
      begin
        article_xml_str = ""
        Timeout::timeout(2, Timeout::Error) do 
          article_xml_str = Hpricot.XML(open(safe_url_str)).to_s
        end
        
        article_xml = APIUtil::response_to_xml(article_xml_str)
        article_text = ""
        # should only be one page and one rev
        article_xml.elements.each('api/query/pages') do |page_xml|
          page_xml.elements.each('page/revisions/rev') do |rev_xml|
            article_text += rev_xml.text unless !rev_xml.text
          end
        end
      rescue Timeout::Error
      rescue # swallow other errors - probably Wikipedia API access problem
      end
    end
    
    article_text
  end
  
  def self.title_to_name(title)
    for title_addition in TITLE_ADDITIONS + ALT_TITLE_ADDITIONS
      title = title.gsub("#{title_addition}", "")
    end
    
    title
  end
  
  def self.about_a_band?(str)
    str.match("band[^s]") || str.match("artist") || str.match("musical") || str.match("music")
  end

  def self.disambiguation_article?(str)
    disambiguation_article = false
    for disambig_str in DISAMBIGUATION_STRS
      match = str.match(disambig_str)
      disambiguation_article = true if match && match.to_s && match.to_s != ""
    end
     
    disambiguation_article
  end
  

  # returns all artists from the label pages on the labels a-z Wikipedia articles
  def self.get_label_artists()
    Log::log(current_user, nil, Log::EVENT, nil, "Starting get_label_artists()")
    labels_and_artists = {}
    barren_labels = []
    for label_title in get_label_titles()
      labels_and_artists[label_title] = []
      label_article_text = pull_article(label_title, nil)
      
      label_article_text = label_article_text.gsub(/\n/, "") # remove newlines
      for band_section_header in BAND_SECTION_HEADERS
        if artists_text_match = label_article_text.match("\=\=[^\=]*#{band_section_header}[^\=]*\=\=[^\=]*")
          artists_text = artists_text_match.to_s
          artists_text = artists_text.gsub(/\*/, "\n\*\s") # put dividery stuff that article extraction seems to rely upon back in
          labels_and_artists[label_title] += get_article_titles_from_text(artists_text)
        end
      end
      
      barren_labels << label_title if labels_and_artists[label_title].length == 0
    end
    
    for label_name in labels_and_artists.keys().sort {|x,y| x <=> y }
      Logger.new(STDOUT).error(label_name)
      Logger.new(STDOUT).error(labels_and_artists[label_name].inspect)
      Logger.new(STDOUT).error("")
    end
    
    Log::log(current_user, nil, Log::EVENT, nil, "Finishing get_label_artists()")
    
    labels_and_artists
  end

  # returns titles for all the labels on the labels a-z Wikipedia articles
  def self.get_label_titles()
    list_of_record_labels_url = "http://en.wikipedia.org/wiki/List_of_record_labels"
    record_labels_for_letter_base_title = "List_of_record_labels_starting_with_"
    record_labels_for_letter_numbers_title = "List_of_record_labels_starting_with_a_number"
    
    label_titles = []
    
    # numbers
    article_text = pull_article(record_labels_for_letter_numbers_title, nil)
    label_titles += get_article_titles_from_text(article_text)
    
    # letters
    for letter in 'A'..'Z'
      record_labels_for_letter_title = record_labels_for_letter_base_title + letter
      article_text = pull_article(record_labels_for_letter_title, nil)
      label_titles += get_article_titles_from_text(article_text)
    end
  
    label_titles
  end
  
  def self.get_article_titles_from_text(text)
    article_titles = []
    raw_article_titles = text.scan(/\[\[.*\]\]/)
    raw_article_titles.each{|raw_article_title| article_titles << extract_title_from_raw_str(raw_article_title) }
    
    article_titles
  end
  
  def self.extract_title_from_raw_str(raw_label_title)
    if complex_label_title = raw_label_title.match(/\[\[(.*)\|/) # complex link so remove pipe
      raw_label_title = complex_label_title.to_s.gsub(/\|/, "")
    end
    
    raw_label_title = raw_label_title.gsub(/\*\s/, "")
    raw_label_title = raw_label_title.gsub(/\[/, "")
    raw_label_title = raw_label_title.gsub(/\]/, "")
  end
end