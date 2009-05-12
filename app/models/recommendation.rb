class Recommendation < ActiveRecord::Base
  belongs_to :search_artist,
             :class_name => "Artist", 
             :foreign_key => "search_artist_id"
  belongs_to :recommended_artist,
             :class_name => "Artist", 
             :foreign_key => "recommended_artist_id"
  belongs_to :user
  
  USER_NUM_RECOMMENDATIONS_TO_GENERATE = 3
  LOGGED_IN_USER_NUM_RECOMMENDATIONS_TO_SHOW = 3
  NON_LOGGED_IN_USER_NUM_RECOMMENDATIONS = 20
  ARTIST_NUM_RECOMMENDATIONS = 10
  ARTIST_NUM_CLOSEST_NODES = 20
  FAVOURITE_ARTIST_CLOSEST_NODES = 20
  MAX_CHILDREN_TO_EXPLORE = 10
  
  LOGGED_IN_USER = "logged_in_user"
  NON_LOGGED_IN_USER = "non_logged_in_user"

  NON_USER_RECOMMENDATION = 0
  USER_RECOMMENDATION = 1

  GENERATE_USER_RECOMMENDATIONS_MAX_TIME = 900
  USER_RECOMMENDATION_GENERATION_INTERVAL_SECS = 60 * 60 * 24 * 7
  
  SAVED = 1
  UNSAVED = 0
  
  def self.get_or_create(user, search_artist, recommended_artist)
    recommendation = self.find_for_user_and_artists(user, search_artist, recommended_artist) if user && user != :false
    if !recommendation
      recommendation = self.new()
      recommendation.user = user unless !user || user == :false
      recommendation.search_artist = search_artist if search_artist
      recommendation.recommended_artist = recommended_artist
      recommendation.time = Time.new()
    end
    
    recommendation
  end
  
  def self.recommend_for_artist(search_artist, current_user)
    recommendations = []
    user = current_user ? current_user : nil
    
    closest_nodes = Treeing::get_closest_nodes(user, search_artist.id, ARTIST_NUM_CLOSEST_NODES)
    closest_nodes = closest_nodes.sort {|x,y| y.get_grade(current_user) <=> x.get_grade(current_user) }
    closest_node_limit = [closest_nodes.length, ARTIST_NUM_RECOMMENDATIONS].min() - 1
    for node in closest_nodes[0..closest_node_limit]
      recommendation = node_to_recommendation(node, user, search_artist, NON_USER_RECOMMENDATION)
      recommendations << recommendation if recommendation.save()
    end

    recommendations
  end
  
  def self.user_recommendations(user)
    self.find(:all, :conditions => "user_id = #{user.id}", :order => "time DESC", :limit => NON_LOGGED_IN_USER_NUM_RECOMMENDATIONS)
  end
  
  def self.automatron(user)
    self.find(:all, :conditions => "user_id = #{user.id} && user_recommendation = 1", :order => "id DESC", :limit => LOGGED_IN_USER_NUM_RECOMMENDATIONS_TO_SHOW)
  end

  def self.generate_user_recommendations()
    i = 0
    started = Time.new() if !started
    for user in User.find_with_recommendations_due(USER_RECOMMENDATION_GENERATION_INTERVAL_SECS)
      saved_for_user = 0
      for favourite_artist in Artist.find_favourite_artists(user)
        for closest_node in Treeing::get_closest_nodes(user, favourite_artist.id, FAVOURITE_ARTIST_CLOSEST_NODES)
          if !recommended?(user, closest_node.get_value_object())
            if node_to_recommendation(closest_node, user, nil, USER_RECOMMENDATION).save()
              saved_for_user += 1 
              i += 1
            end
          end
        
          break if saved_for_user >= USER_NUM_RECOMMENDATIONS_TO_GENERATE
          return i if Util::out_of_time(started, GENERATE_USER_RECOMMENDATIONS_MAX_TIME, "generate_user_recommendations", true)
        end
        
        break if saved_for_user >= USER_NUM_RECOMMENDATIONS_TO_GENERATE
      end
    end
    
    i
  end

  # creates recommendation from passed node and returns it
  def self.node_to_recommendation(node, user, search_artist, user_recommendation)
    recommendation = self.get_or_create(user, search_artist, node.get_value_object())    
    recommendation.user_recommendation = user_recommendation
    recommendation.chain = node.get_chain().join(", ")
    recommendation.grade = node.get_grade(user)
    recommendation.time = Time.new() # set recommended time to now (will be an update if already recced)
    
    recommendation
  end

  def self.get_last(user)
    self.find(:first, :conditions => "user_id = #{user.id} && user_recommendation = 1", :order => 'time DESC')
  end

  def self.find_for_user_and_artists(user, search_artist, recommended_artist)
    conditions = "user_id = #{user.id} && recommended_artist_id = #{recommended_artist.id} "
    conditions += " && search_artist_id = #{search_artist.id} " if search_artist
    self.find(:first, :conditions => conditions)
  end
  
  def chain_links()
    split_chain = []
    split_chain = self.chain.split(", ") if self.chain
    Linking::chain_to_links(split_chain)
  end
  
  def self.get_where_artist_sought_or_recommended(artist)
    self.find(:all, :conditions => "search_artist_id = #{artist.id} || recommended_artist_id = #{artist.id}")
  end
  
  def self.recommended?(user, artist)
    self.find(:first, :conditions => "user_id = #{user.id} && recommended_artist_id = #{artist.id}")
  end
  
  def get_starting_artist()
    starting_artist = search_artist
    starting_artist = Linking::get_starting_artist(self.chain.split(", ")) if !starting_artist # non search rec so pull starting artist from chain
    
    starting_artist
  end
  
  def self.get_saved(user)
    self.find(:all, :conditions => "user_id = #{user.id} && saved = 1", :order => "time ASC")
  end
  
  def saved?()
    self.saved == 1
  end
  
  def switch_save_state(new_state)
    self.saved = new_state
    self.save()
  end
end