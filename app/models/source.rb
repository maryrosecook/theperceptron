require 'net/http'

['hpricot', 'cgi', 'open-uri'].each {|f| require f}
require 'uri'

class Source < ActiveRecord::Base
  has_and_belongs_to_many :links
  has_many :source_grades
  has_many :temp_artist_associations
  
  EPITONIC_SIMILAR_SOURCE = "EpitonicSimilarSource"
  EPITONIC_OTHER_SOURCE = "EpitonicOtherSource"
  WIKIPEDIA_LABEL_SOURCE = "WikipediaLabelSource"
  HYPE_MACHINE_BLOG_SOURCE = "HypeMachineBlogSource"
  MYSPACE_BAND_FRIENDS_SOURCE = "MyspaceBandFriendsSource"
  TINY_MIX_TAPES_SOURCE = "TinyMixTapesSource"
  MUXTAPE_SOURCE = "MuxtapeSource"
  MYSPACE_BILLS_SOURCE = "MyspaceBillsSource"
  USER_SUGGESTIOM_SOURCE = "UserSuggestionSource"
  ABSOLUTE_PUNK_SOURCE = "AbsolutePunkSource"
  LASTFM_SOURCE = "LastfmSource"
  EMUSIC_SOURCE = "EmusicSource"
  
  RETRACE = true
  NO_RETRACE = false
  
  NO_RENEW = false
  RENEW = true
  
  PATH_IS_WEBSITE = true
  PATH_IS_NOT_WEBSITE = false
  
  DEFAULT_PAGE_CONTENT_SLEEP = 8
  
  def self.scrape(in_starting_artist, renew_connection, max_time)
    Log::log(nil, nil, Log::SCRAPE, nil, "Starting a #{self.to_s} scrape.")
    @unexplored_artists = []
    @explored_artists = []
    starting_artist = in_starting_artist
    started = Time.new()
    
    http = get_http_connection(get_host()) # setup http connection

    i = 0
    past_starting_artists = []
    # work backwards through all artists w/ paths, starting the spidering from each
    while true
      if !starting_artist
        starting_artist = get_starting_artist(past_starting_artists)
      end
      
      past_starting_artists << starting_artist
      Logger.new(STDOUT).error("Starting with: " + starting_artist.name)
      @unexplored_artists << starting_artist
      starting_artist = nil
      while @unexplored_artists.length() > 0
        i += spider(@unexplored_artists[0], http)
        @unexplored_artists[0].path = nil # dump path - done w/ following this artist
        @unexplored_artists[0].save()
        @unexplored_artists.delete_at(0)
        i += 1
        if max_time && Util::out_of_time(started, max_time, "#{self.to_s}.scrape", Log::DO_NOT_LOG)
          Log::log(nil, nil, Log::SCRAPE, nil, "Finishing a #{self.to_s} scrape.  Added #{i} artists.")
          return i
        end
      end
      
      # renew connection periodically to try andn avoid conn resets
      if renew_connection
        http.finish()
        http = get_http_connection(get_host())
      end
    end
    
    Log::log(nil, nil, Log::SCRAPE, nil, "Finishing a #{self.to_s} scrape.  Added #{i} artists.")
    
    i
  end
  
  # carves out the string with artist list inside
  def self.get_content_section(page_content, start, finish)
    similar_artists_raw = page_content
    similar_artists_raw = similar_artists_raw.gsub(/\n/, " ")
    similar_artists_raw = similar_artists_raw.match("#{start}(.+)#{finish}").to_s
    similar_artists_raw = similar_artists_raw.gsub("#{start}", "")
    similar_artists_raw = similar_artists_raw.gsub("#{finish}", "")
    
    similar_artists_raw
  end
  
  def self.get_http_connection(host)
    url = URI.parse(host)
    http = Net::HTTP.start(url.host, url.port)
  end
  
  # uses passed http connection to get content of passed url_str
  def self.get_page_content(http, url_str, in_sleep_time)
    content = ""
    begin
      url = URI.parse(url_str)
      req = Net::HTTP::Get.new(url.path + "?" + url.query.to_s)
    
      begin
        article_xml_str = ""
        Timeout::timeout(10, Timeout::Error) do 
          res = http.request(req)
          content = res.body unless !res
        end
        in_sleep_time ? sleep_time = in_sleep_time : sleep_time = DEFAULT_PAGE_CONTENT_SLEEP
        sleep(sleep_time)
      rescue Timeout::Error
      rescue
      end
    rescue
      Log::log(nil, nil, Log::ERROR, nil, "Tried to get bad URL: " + url_str)
    end
    
    content
  end
  
  # returns rss feed of latest links for passed delicious user
  def self.get_xml_feed(url_str)
    xml = ""
    begin
      Timeout::timeout(10, Timeout::Error) do 
        if xml_str = Hpricot.XML(open(url_str)).to_s
          xml = APIUtil::response_to_xml(xml_str) if xml_str && xml_str != ""
        end
      end
    rescue Timeout::Error
    end

    xml
  end
  
  # saves child artists, saves link between child and parent, adds child to @unexplored_artists
  def self.add_artists_and_links(parent_artist, artists_and_links, source, retrace, path_is_website)
    i = 0
    for artist_name in artists_and_links.keys()
      child_artist = Artist::get_or_create(artist_name)
      path = artists_and_links[artist_name]
      if path && path != "" # link exists so put on child and add to @unexplored_artists
        # update child_artist w/ path info
        child_artist.path = path
        child_artist.set_myspace_url_or_website(source.class.get_host() + path) if path_is_website # no web currently and path deemed same as web
        
        # decide whether to explore artist
        if !@unexplored_artists.include?(child_artist) && !@explored_artists.include?(child_artist) # artist not explored, nor queued
          # artist explored if on retrace, artist hasn't been met before, or artist not linked for cur source yet
          explore_artist = false
          if retrace
            explore_artist = true
          else
            if db_artist = Artist.find_by_name(child_artist.name)
              explore_artist = true
              for link in db_artist.links()
                if link.sources().include?(source)
                  explore_artist = false
                  break
                end
              end
            else
              explore_artist = true
            end
          end

          if explore_artist
            @unexplored_artists << child_artist
            i += 1
          end

          Logger.new(STDOUT).error(child_artist.name)
        end
      end
      child_artist.save()
      
      # link
      link = Link::get_or_create(parent_artist, child_artist, source) # create/get link and add source
      link.save()
    end
    
    @explored_artists << parent_artist
    
    i
  end

  # returns most recently captured artist that has a URL specifed
  def self.get_starting_artist(source, exclude_artists)
    starting_place_artist = nil
    for link in source.links.sort {|x,y| y.second_artist_id <=> x.second_artist_id }
      artist = link.second_artist
      if artist.path && artist.path != "" && !exclude_artists.include?(artist)
        starting_place_artist = artist
        break
      end
    end
    
    starting_place_artist  
  end

  # gets source with passed constant for type
  def self.get(source)
    Source.find(:first, :conditions => "type = '#{source}'")
  end
  
  def get_link_count()
    count_results = ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM links_sources WHERE links_sources.source_id = #{self.id};")
    tot_source_links = count_results.fetch_row()[0]
    count_results.free()
    
    tot_source_links
  end
  
  def get_positive_count()
    positive_count = 0
    for link_rating in LinkRating.find(:all)
      count_results = ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM links_sources 
                                                             WHERE links_sources.source_id = #{self.id}
                                                             AND links_sources.link_id = #{link_rating.link_id};")
      count = count_results.fetch_row()[0]
      count_results.free()
      positive_count += RatingPlace::POSITIVE_COUNTS[link_rating.rating] if count.to_i > 0
    end

    positive_count
  end
  
  def get_overlap_count()
    overlap_count = 0
    self.links().each {|source_link| overlap_count += 1 if source_link.sources().length == 1 }
    
    overlap_count
  end
end