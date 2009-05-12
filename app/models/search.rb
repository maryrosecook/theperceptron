class Search < ActiveRecord::Base
  belongs_to :search_artist,
             :class_name => "Artist", 
             :foreign_key => "search_artist_id"
  belongs_to :user
  
  DEFAULT_RECENT_SEARCHES_COUNT = 20
  MAX_RECENT_SEARCHES_COUNT = 200
  
  SEARCH_CANNED = "Enter an artist you like"
  
  def self.search(query)
    artists = []
    query = query.strip()
    
    exact_artist = Artist.find_for_name(query)
    artists << exact_artist if exact_artist
    if artists.length == 0 # no go so try removing articles
      query_no_articles = query.gsub(/^the /i, "").gsub(/^a /i, "")
      artists += Artist.name_full_text_search(query_no_articles)
      if artists.length == 0 # still no go so try full text search
        artists += Artist.name_full_text_search(query)
      end
    end

    artists
  end
  
  def self.new_from_searching(user, body, search_artist, search_result_count, hand_search)
    search = self.new()
    search.user = user unless user == :false
    search.body = body
    search.result_count = search_result_count
    search.search_artist = search_artist
    search.hand_search = hand_search
    search.time = Time.new()
    
    search
  end
  
  def self.get_all_searches(offset, limit)
    self.find(:all, :order => 'time DESC', :offset => offset, :limit => limit)
  end
  
  def self.new_after_user_search(body)
    search = self.new()
    search.body = body
    
    search
  end
  
  def self.find_hand_searches(user)
    self.find(:all, :conditions => "user_id = #{user.id} && hand_search = 1")
  end
  
  def self.has_hand_sought?(user, artist)
    self.find(:first, :conditions => "user_id = #{user.id} && hand_search = 1 && search_artist_id = #{artist.id}")
  end
  
  def self.find_hand_searches_admin(offset, limit)
    self.find(:all, :conditions => "hand_search = 1", :offset => offset, :limit => limit, :order => 'time DESC')
  end
  
  def self.get_hand_searches_by_user()
    searches = []
    for search in Search.find(:all,
                              :conditions => "hand_search = 1 && user_id IS NOT NULL && search_artist_id IS NOT NULL",
                              :order => "user_id ASC, time ASC")
      searches[searches.length] = search
    end
    
    searches
  end
  
  def self.find_in_temporal_range(older, newer)
    self.find(:all, :conditions => { :time => older..newer, :hand_search => 1 })
  end
  
  def self.find_artist_in_temporal_range(older, newer, artist_name)
    self.find(:all, :conditions => { :time => older..newer, :hand_search => 1, :search_artist_id => Artist.find_by_name(artist_name).id })
  end
end