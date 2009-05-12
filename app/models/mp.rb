class Mp < ActiveRecord::Base
  
  def self.new_from_xml(person_id, name)
    mp = self.new()
    mp.person_id = person_id
    mp.name = name
    return mp
  end
end
