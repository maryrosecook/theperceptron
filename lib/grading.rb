module Grading
  NUM_LINK_GRADES_TO_RECALCULATE_IN_ONE_GO = 5000
  
  # recalculates source grades, then all links grades
  def self.recalculate_link_grades()
    i = 0
    now = Time.new()
    offset = Odd.get_data("last_link_offset")
    for link in Link.find(:all, :offset => offset, :limit => NUM_LINK_GRADES_TO_RECALCULATE_IN_ONE_GO)
      link.recalculate_grade(now)
      i += 1
    end
    
    Util::set_offset("last_link_offset", i, NUM_LINK_GRADES_TO_RECALCULATE_IN_ONE_GO)
    
    i
  end
end