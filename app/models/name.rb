class Name < ActiveRecord::Base
  
  def self.new_with_rank(body, rank)
    name = self.new()
    name.body = body
    name.rank = rank
    
    name
  end
end