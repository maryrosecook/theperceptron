module Stating
  def self.most_searched_bands_this_week()
    searches = Search.find_in_temporal_range(1.week.ago, Time.now)
    Util::rank(searches, "body")[0..9]
  end
  
  def self.most_searched_bands_a_week_ago()
    searches = Search.find_in_temporal_range(2.weeks.ago, 1.week.ago)
    Util::rank(searches, "body")[0..9]
  end
end