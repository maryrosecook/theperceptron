class Link < ActiveRecord::Base
  belongs_to :first_artist,
             :class_name => "Artist", 
             :foreign_key => "first_artist_id"
  belongs_to :second_artist,
             :class_name => "Artist", 
             :foreign_key => "second_artist_id"
  has_and_belongs_to_many :sources
  has_and_belongs_to_many :users
  has_many :link_ratings
  
  SOURCES_PROP = 0.5
  ALL_RATINGS_PROP = 0.5
  
  USER_LIKED_GRADE = 1
  USER_DISLIKED_GRADE = 0
  
  def valid?()
    self.first_artist_id != self.second_artist_id
  end
  
  # return LIKED/DISLIKED grade or pre-calculated grade if user hasn't rated link
  def get_grade(user)
    final_grade = self.grade
    user_link_rating = self.get_rating_for(user) if user && user != :false
    if user_link_rating
      if user_link_rating.rating == RatingPlace::LIKED
        final_grade = USER_LIKED_GRADE
      elsif user_link_rating.rating == RatingPlace::DISLIKED
        final_grade = USER_DISLIKED_GRADE
      end
    end  
    
    final_grade
  end
  
  # returns average of grades for all sources for this link
  def recalculate_grade(nowish)
    grade = 0
    
    # all ratings grade (might be negative)
    all_ratings_grade = 0
    ratings = {RatingPlace::LIKED => 0, RatingPlace::DISLIKED => 0}
    tot_ratings = 0
    for link_rating in self.link_ratings()
      if ratings.keys().include?(link_rating.rating) # only count likes and dislikes
        ratings[link_rating.rating] += 1
        tot_ratings += 1
      end
    end
    
    if tot_ratings > 0
      raw_rating = ((ratings[RatingPlace::LIKED] - ratings[RatingPlace::DISLIKED]) / tot_ratings).to_f
      all_ratings_grade = raw_rating * ALL_RATINGS_PROP
    end

    self.grade = (get_total_source_grade() * SOURCES_PROP) + all_ratings_grade
    self.grade_recalculated = nowish
    self.save()
  end
  
  def self.get_or_create(artist_1, artist_2, source)
    link = find_by_artists(artist_1.id, artist_2.id)
    if !link
      link = Link.new()                                      
      link.first_artist = artist_1
      link.second_artist = artist_2
      link.grade = 0.01 # force low grade
    end
    link.sources() << source unless link.sources().include?(source)
    
    link
  end
  
  def self.find_by_artists(artist_1_id, artist_2_id)
    existing_link = self.find(:first,
                              :conditions => "(first_artist_id = #{artist_1_id} && second_artist_id = #{artist_2_id})
                                              || (first_artist_id = #{artist_2_id} && second_artist_id = #{artist_1_id})")
  end
  
  def self.find_by_artist(artist_id)
    self.find(:all,
              :conditions => "first_artist_id = #{artist_id} || second_artist_id = #{artist_id}")
  end
  
  def get_rating_for(user)
    LinkRating.find_for_user_link(user, self)
  end
  
  def get_total_source_grade()
    tot_source_grade = 0
    self.sources().each {|source| tot_source_grade += source.grade }

    tot_source_grade
  end
end