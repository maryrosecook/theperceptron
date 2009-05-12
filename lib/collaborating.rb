module Collaborating
  
  def self.test()
    user = User.find(3)
    
    for user in User.find(:all, :conditions => 'fake = 0')
      related_users = []
      for artist in Collaborating::get_positively_rated_artists(user)
        for rated_artist in RatedArtist.find(:all, 
                                             :conditions => "user_id != #{user.id} && artist_id = #{artist.id}")
          if RatingPlace::is_positive?(rated_artist.rating)
            related_users << rated_artist.user
          end
        end
      end

      similar_users = Util::items_occurring_more_than_once(related_users)
      Logger.new(STDOUT).error(user.username)
      for similar_user in similar_users
        Logger.new(STDOUT).error("  " + similar_user.username)
        for common_artist in get_common_artists(user, similar_user)
          Logger.new(STDOUT).error("      " + common_artist.name)
        end
      end
    end
  end
  
  def self.get_common_artists(user_1, user_2)
    common_artists = []
    user_1_artists = get_positively_rated_artists(user_1)
    user_2_artists = get_positively_rated_artists(user_2)
    
    for user_1_artist in user_1_artists
      for user_2_artist in user_2_artists
        common_artists << user_1_artist if user_1_artist == user_2_artist
      end
    end
    
    common_artists
  end
  
  def self.get_positively_rated_artists(user)
    positively_rated_artists = []
    for rated_artist in user.rated_artists()
      positively_rated_artists << rated_artist.artist if RatingPlace::is_positive?(rated_artist.rating)
    end
    
    positively_rated_artists.uniq()
  end
end