class SubSource < ActiveRecord::Base
  has_and_belongs_to_many :artists
  belongs_to :source
  
  def self.get_or_create(name, source)
    sub_source = find_by_name_and_source(name, source)
    if !sub_source
      sub_source = self.new()                                      
      sub_source.name = name
      sub_source.source = source
    end
    
    sub_source
  end
  
  def self.find_by_name_and_source(name, source)
    self.find(:first, :conditions => "name = '#{name}' && source_id = #{source.id}")
  end
end