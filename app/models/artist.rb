class Artist < ActiveRecord::Base
  has_many :saves
  has_many :flags
  has_many :rated_artists
  has_many :recommendations
  has_many :searches
  has_and_belongs_to_many :sub_sources
  has_many :rejections
  
  validates_length_of :name, :maximum => 255
  
  SUMMARY_LENGTH = 60
  DETAILS_GRAB_INTERVAL_SECS = 31104000
  
  SUMMARY = "summary"
  ARTICLE_TITLE = "article_title"
  SAMPLE_TRACK_URL = "sample_track_url"
  WEBSITE = "website"
  MYSPACE_URL = "myspace_url"
  
  REFRESH = "refresh"
  REJECT = "reject"

  WEBSITE = "website"
  MYSPACE = "myspace"
  WIKIPEDIA = "wikipedia"
  INSOUND = "insound"
  AMAZONCOM = "amazoncom"
  
  def links()
    Link.find_by_artist(self.id)
  end
  
  def self.find_favourite_artists(user)
    favourite_artists = []
    RatedArtist.find_liked(user).each {|rated_artist| favourite_artists << rated_artist.artist unless !rated_artist.artist }
    Search.find_hand_searches(user).each {|search| favourite_artists << search.search_artist unless !search.search_artist }

    favourite_artists.uniq()
  end
  
  def get_thing(thing)
    data = ""
    if thing == SUMMARY
      data = self.get_summary()
    elsif thing == SAMPLE_TRACK_URL
      data = self.get_sample_track_url()
    elsif thing == WEBSITE
      data = self.get_website()
    elsif thing == MYSPACE_URL
      data = self.get_myspace_url()
    end
    
    data
  end
  
  def self.rate(user, artist, rating, chain_str)
    RatedArtist.rate_artist(user, artist, rating)
    LinkRating::rate_links(user, rating, chain_str)
  end
  
  def self.get_or_create(name)
    artist = find_for_name(name)
    if !artist
      artist = Artist.new()
      artist.name = sanitise_name(name)
      artist.generate_safe_name()
    end
    
    artist
  end

  def set_myspace_url_or_website(url)
    if url && url != ""
      myspace_match = url.match(/myspace/i)
      if myspace_match && myspace_match.to_s && myspace_match.to_s != "" # is myspace
        set_myspace_url(url)
      else
        set_website(url)
      end
    end
  end

  def set_website(website)
    self.website = website
  end

  def set_myspace_url(myspace_url)
    self.myspace_url = myspace_url
  end

  def set_summary(summary)
    self.summary = summary
  end

  def set_article_title(article_title)
    self.article_title = article_title
  end
  
  def set_sample_track_url(sample_track_url)
    self.sample_track_url = sample_track_url
  end
  
  def get_summary()
    ret_summary = ""
    if self.summary && self.summary != ""
      ret_summary = self.name + " " + Util::truncate(self.summary, SUMMARY_LENGTH, true)
    end
    
    ret_summary
  end
  
  def get_article_url()
    Wikipediaing::compose_article_url(self.article_title)
  end
  
  def get_sample_track_url()
    sample_track_url && sample_track_url != "" ? sample_track_url : ""
  end
  
  def get_website()
    website && website != "" ? website : ""
  end
  
  def get_myspace_url()
    myspace_url && myspace_url != "" ? myspace_url : ""
  end
  
  def get_emusic_url()
    show_affiliate_link?() ? "http://www.emusic.com/search.html?mode=a&QT=#{Artist.sanitise_name(self.name)}&fref=2486256" : ""
  end

  def get_insound_url()
    show_affiliate_link?() ? "http://search.insound.com/search/searchmain.jsp?select=artist&query=#{Artist.sanitise_name(self.name)}&from=8362" : ""
  end
  
  def get_amazoncom_url()
    show_affiliate_link?() ? "http://www.amazon.com/gp/search?ie=UTF8&keywords=#{Artist.sanitise_name(self.name)}&tag=theperceptron-20&index=music&linkCode=ur2&camp=1789&creative=9325" : ""
  end
  
  def show_affiliate_link?()
    summary = get_summary()
    sample_track_url = get_sample_track_url()
    
    summary != "" || sample_track_url != ""
  end
  
  def get_elsewhere_intermediary_url(place, recommendation)
    recommendation ? recommendation_id = recommendation.id : recommendation_id = ""
    passable_url = self.get_elsewhere_url(place).gsub(/&/, "%26")
    "/artist/elsewhere/?url=#{passable_url}&artist_id=#{self.id}&place=#{place}&recommendation_id=#{recommendation_id}"
  end
  
  def get_elsewhere_url(place)
    url = nil
    if place == Artist::WEBSITE
      url = self.get_website()
    elsif place == Artist::MYSPACE
      url = self.get_myspace_url()
    elsif place == Artist::WIKIPEDIA
      url = self.get_article_url()
    elsif place == Artist::INSOUND
      url = self.get_insound_url()
    elsif place == Artist::AMAZONCOM
      url = self.get_amazoncom_url()
    end
    
    url
  end
  
  # sets appriate fields to nil on artist and returns a new rejection object
  def switch_thing(thing, act)    
    if thing == ARTICLE_TITLE || thing == SUMMARY
      data = self.article_title
      self.summary = nil
      self.article_title = nil
      self.rejections() << Rejection.new_from_rejecting(Artist::ARTICLE_TITLE, data) if act == Artist::REJECT
    elsif thing == SAMPLE_TRACK_URL
      data = sample_track_url
      self.sample_track_url = nil
      self.rejections() << Rejection.new_from_rejecting(thing, data) if act == Artist::REJECT
    elsif thing == WEBSITE
      data = website
      self.website = nil
      self.rejections() << Rejection.new_from_rejecting(thing, data) if act == Artist::REJECT
    elsif thing == MYSPACE_URL
      data = myspace_url
      self.myspace_url = nil
      self.rejections() << Rejection.new_from_rejecting(thing, data) if act == Artist::REJECT
    end
  end
  
  def self.find_for_name(name)
    artist = nil
    sanitised_name = sanitise_name(name)
    artist = self.find(:first, :conditions => "name = \"" + sanitised_name + "\"") 
    artist = self.find(:first, :conditions => "safe_name = \"" + sanitised_name + "\"") if !artist
    if !artist
      if other_name = OtherName.find(:first, :conditions => "name = \"" + sanitised_name + "\"")
        artist = other_name.artist
      end
    end
    
    artist
  end
  
  def get_safe_name()
    self.safe_name && self.safe_name != "" ? safe_name : name
  end
  
  def generate_safe_name()
    safe_name = self.name.downcase().gsub(/\W/, "")
    name_try = safe_name
    
    i = 1
    while(Artist.find_for_name(name_try))
      name_try = safe_name + i.to_s
      i += 1
    end
    
    self.safe_name = name_try
  end
  
  def self.sanitise_name(name)
    Util::esc_for_speech(Util::cap_the_bitch(name).strip())
  end
  
  def self.name_full_text_search(name)
    artists = []
    artists += self.find(:all, :conditions => "name like \"%" + sanitise_name(name) + "%\"", :limit => 3)
    OtherName.find(:all, :conditions => "name like \"%" + sanitise_name(name) + "%\"", :limit => 3).each {|artist| artists << artist }
    
    artists.uniq()
  end
  
  def self.count_not_null_not_empty(column)
    self.count(:conditions => "#{column} IS NOT NULL && #{column} != ''")
  end
  
  def name_to_query
    Util::str_to_query(self.name)
  end
  
  def self.query_to_name(query)
    query.gsub(/\+/, " ")
  end
end