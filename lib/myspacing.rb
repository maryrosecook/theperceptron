module Myspacing
  
  def self.is_band_page?(page_content)
    match = page_content.match(/General Info/)
    
    match && match.to_s && match.to_s != ""
  end
  
  def self.is_band_name?(name)
    match = name.match(/Records/)
    record_company = match && match.to_s && match.to_s != ""
    
    !record_company
  end
end