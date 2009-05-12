class LinkRating < ActiveRecord::Base
  belongs_to :user
  belongs_to :artist
  belongs_to :link

  def self.get_or_create(user, link)
    link_rating = find_for_user_link(user, link)
    if !link_rating
      link_rating = self.new()
      link_rating.user = user
      link_rating.link = link
      link_rating.time = Time.new()
    end
    
    link_rating
  end
  
  def self.rate_links(user, new_rating, chain_str)
    if chain_str
      for link in Linking::chain_to_links(chain_str.split(", "))
        link_rating = get_or_create(user, link)
        link_rating.rating = new_rating if RatingPlace.first_more_important_than_second(new_rating, link_rating.rating)
        link_rating.save()
      end
    end
  end
  
  def self.find_for_user_link(user, link)
    self.find_for_user_link_rating(user, link, nil)
  end
  
  private
  
    # returns most recent rating of passed link
    def self.find_for_user_link_rating(user, link, rating)
      conditions = "user_id = #{user.id} && link_id = #{link.id} "
      conditions += " && rating = '#{rating}'" if rating
      self.find(:first, :conditions => conditions)
    end
end