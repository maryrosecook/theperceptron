class Communique < ActiveRecord::Base
  belongs_to :user
  
  def self.new_blank(user)
    communique = self.new()
    communique.body = "Feature requests, bug reports, rants, whatever."
    communique.user = user if user && user != :false

    communique
  end
  
  def self.get_paged(offset, limit)
    self.find(:all, :order => 'created_at DESC', :offset => offset, :limit => limit)
  end
end