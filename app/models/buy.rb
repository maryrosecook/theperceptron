class Buy < ActiveRecord::Base  
  belongs_to :artist
  
  def self.new_from_scrape(artist, username)
    buy = self.new()
    buy.artist = artist
    buy.username = username
  
    buy
  end
end