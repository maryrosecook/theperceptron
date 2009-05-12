# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def self.get_random_aphorism()
    bodies = []
    Aphorism.find(:all).each {|a| bodies << a.body }
    aphorism = Util::rand_el(bodies << "")
    
    aphorism
  end
end