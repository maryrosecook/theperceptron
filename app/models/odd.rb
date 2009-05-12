class Odd < ActiveRecord::Base
  
  def self.get_data(name)
    data = nil
    if odd = self.find(:first, :order => 'id DESC')
      data = odd[name]
    end
    
    data
  end
  
  def self.set_data(name, data)
    if odd = self.find(:first, :order => 'id DESC')
      odd[name] = data
      odd.save()
    end
  end
end