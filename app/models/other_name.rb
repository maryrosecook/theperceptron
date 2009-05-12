class OtherName < ActiveRecord::Base
  belongs_to :artist
  
  validates_uniqueness_of :name, :case_sensitive => false
  
  def self.new_from_adding(artist, name)
    other_name = self.new()
    other_name.artist = artist
    other_name.name = name
    
    other_name
  end
end