class RatingPlace
  
  LIKED = "liked"
  DISLIKED = "disliked"

  INSOUND = "insound"
  AMAZONCOM = "amazoncom"

  PLAYLIST = "playlist"  
  WEBSITE = "website"
  MYSPACE = "myspace"
  WIKIPEDIA = "wikipedia"
  
  TIERS = [[LIKED, DISLIKED], [INSOUND, AMAZONCOM], [WEBSITE, MYSPACE, WIKIPEDIA, PLAYLIST]]
  
  ALL = [LIKED, DISLIKED, INSOUND, AMAZONCOM, WEBSITE, MYSPACE, WIKIPEDIA, PLAYLIST]
  RATINGS = [LIKED, DISLIKED]
  ACTIONS = [PLAYLIST]
  PLACES = [WEBSITE, MYSPACE, WIKIPEDIA, INSOUND, AMAZONCOM]
  SHOPS = [INSOUND, AMAZONCOM]
  
  POSITIVE_COUNTS = {LIKED => 5, DISLIKED => -5,
                     INSOUND => 2, AMAZONCOM => 2,
                     WEBSITE => 1, MYSPACE => 1, WIKIPEDIA => 1, PLAYLIST => 1}
  
  def self.get_tier(tiers, item)
    return_tier = 999
    i = 0
    for tier in tiers
      if tier.include?(item)
        return_tier = i
        break
      end
      i += 1
    end
    
    return_tier
  end
  
  def self.first_more_important_than_second(first, second)    
    get_tier(TIERS, first) <= get_tier(TIERS, second) ? true : false
  end
  
  def self.is_rating?(rating)
    RATINGS.include?(rating)
  end
  
  def self.is_positive?(rating)
    POSITIVE_COUNTS.include?(rating) && POSITIVE_COUNTS[rating] > 0
  end
end