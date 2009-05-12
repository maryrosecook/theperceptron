class SourceGrade < ActiveRecord::Base
  belongs_to :source
  
  UNINITIALISED_GRADE_VALUE = 0.1
  
  def self.get_latest_source_grade(source)
    latest_source_grade_value = UNINITIALISED_GRADE_VALUE
    if latest = self.find(:first, :conditions => "source_id = #{source.id}", :order => "calculation_number DESC")
      latest_source_grade_value = latest.grade
    end
    
    latest_source_grade_value
  end
  
  def self.recalculate_source_grades()
    Log::log(nil, nil, Log::EVENT, nil, "recalculate_source_grades()")
    
    raw_grade_sum = 0
    raw_grades = {}
    for source in Source.find(:all)
      if source.type.to_s != "UserSuggestionSource"
        raw_grades[source.id] = calculate_raw_grade(source)
        raw_grade_sum += raw_grades[source.id]
      end
    end
    
    i = 0
    latest_calculation_number = SourceGrade::get_next_calculation_number()
    for source in Source.find(:all)
      if source.type.to_s != "UserSuggestionSource"      
        grade = raw_grades[source.id] * (1 / raw_grade_sum)
      else
        grade = 0.1111111
      end
      
      source_grade = self.new_from_recalculating(source, latest_calculation_number, grade)
    
      # update grade on actual source (for speed)
      if source_grade.save()
        source.grade = source_grade.grade
        source.save()
        i += 1
      end
    end
    
    i
  end
  
  def self.calculate_raw_grade(source)
    (source.get_positive_count() / source.get_link_count().to_f)
  end
  
  def self.new_from_recalculating(source, calculation_number, grade)
    source_grade = self.new()
    source_grade.source = source
    source_grade.calculation_number = calculation_number
    source_grade.grade = grade
    source_grade.time = Time.new()
    
    source_grade
  end
  
  def self.get_next_calculation_number()
    get_latest_calculation_number() + 1
  end

  def self.get_latest_calculation_number()
    latest_calculation_number = 0
    if latest_source_grade = self.find(:first, :order => "calculation_number DESC")
      latest_calculation_number = latest_source_grade.calculation_number
    end
      
    latest_calculation_number
  end
end