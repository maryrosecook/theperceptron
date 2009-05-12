class Rejection < ActiveRecord::Base
  belongs_to :artist
  
  def self.new_from_rejecting(thing, data)
    rejection = self.new()
    rejection.thing = thing
    rejection.data = data
    
    rejection
  end
  
  # returns true if has been a rejection for passed data of type thing for passed artist
  def self.rejected?(artist, thing, data)
    self.find(:first, :conditions => "artist_id = #{artist.id} && thing = '#{thing}' && data = \"" + Util::esc_for_speech(data.strip()) + "\"")
  end
end