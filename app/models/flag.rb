class Flag < ActiveRecord::Base
  belongs_to :artist
  belongs_to :user
  
  # returns true if passed user has flagged passed artist
  def self.flagged?(user, artist)
    Flag.find(:first, :conditions => "user_id = #{user.id} && artist_id = #{artist.id} && resolved != 1")
  end
  
  def self.new_primer()
    flag = self.new()
    flag.reason = "Wrong track? Wrong summary?"
    flag.time = Time.new()
    
    flag
  end
  
  def self.get_unresolved_paged(offset, limit)
    self.find(:all, :conditions => "resolved != 1", :order => 'time DESC', :offset => offset, :limit => limit)
  end
  
  def self.get_unresolved()
    self.find(:all, :conditions => "resolved != 1")
  end
end