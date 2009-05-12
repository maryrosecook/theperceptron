class RatedArtist < ActiveRecord::Base
  belongs_to :artist
  belongs_to :user
    
  HIDDEN = 1
  SHOWING = 0
  
  def self.get_or_create(user, artist)
    rated_artist = find_for_user_and_artist(user, artist)
    if !rated_artist
      rated_artist = self.new()
      rated_artist.artist = artist
      rated_artist.user = user
    end
    
    rated_artist
  end
  
  def self.rate_artist(user, artist, new_rating)
    rated_artist = get_or_create(user, artist)
    rated_artist.rating = new_rating if RatingPlace.first_more_important_than_second(new_rating, rated_artist.rating)
    rated_artist.save()
  end

  def self.find_for_user_and_artist(user, artist)
    self.find(:first, :conditions => "user_id = #{user.id} && artist_id = #{artist.id}")
  end
  
  def self.find_liked(user)
    self.find(:all, :conditions => "user_id = #{user.id} && rating = '#{RatingPlace::LIKED}'", :order => 'id DESC')
  end
  
  def self.has?(user, artist, rating)
    self.find(:first, :conditions => "user_id = #{user.id} && artist_id = #{artist.id} && rating = '#{rating}'")
  end
end