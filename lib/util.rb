module Util
  Util::LIM_NO_OFFSET = 0
  Util::LIM_INFINITE = 999999999999
  
  def self.strip_html(str)
    str.gsub(/<\/?[^>]*>/, "")
  end
  
  def self.esc_for_speech(str)
    str = str.gsub(/\\"/, 'fhdskfhksdjsdfh').gsub(/"/, '\"').gsub(/fhdskfhksdjsdfh/, '\"')
  end
  
  # shorts passed str to passed word_count
  def self.truncate(str, word_count, elipsis)
    words = str.split()
    truncated_str = str.split[0..(word_count-1)].join(" ")
    if elipsis && words.length() > word_count
      truncated_str += "..."
    end
    
    truncated_str
  end
  
  # returns random element of array
  def self.rand_el(array)
    el = nil
    el = array[rand()*(array.length-1)] unless !array || array.length < 1
    
    el
  end
  
  def self.scrub_fastidious_entities(str)
    str.gsub(/&#8217;/, "'").gsub(/&amp;/, "&")
  end
  
  # returns true and logs out of time error if started + max_time > now
  def self.out_of_time(started, max_time, desc, log)
    out_of_time = false
    if Time.new().tv_sec > started.tv_sec + max_time # kill the process if more than max_time old
      out_of_time = true
      Log::log(nil, nil, Log::OUT_OF_TIME, nil, desc) if log
    end
      
    out_of_time
  end
  
  def self.str_to_query(str)
    str.gsub(/ /, "+").gsub(/"/,"&#34;").gsub(/\./,"%2E").gsub(/\//,"%2f")
  end
  
  # capitalises first letter of each word
  def self.cap_the_bitch(str)
    str.downcase().split(/\s+/).each{|word| word.capitalize! }.join(' ') 
  end
  
  def self.parse_js_response(request)
    word_raw = request.raw_post || request.query_string
    word_raw = word_raw.gsub(/(.*)authenticity_token.*/, "\\1")
    word_raw.gsub(/&/, "")
  end
  
  def self.items_occurring_more_than_once(items)
    ret_items_occurring_more_than_once = []
    for item_a in items
      occurrences = 0
      items.each {|item_b| occurrences += 1 if item_a == item_b }
      ret_items_occurring_more_than_once << item_a if occurrences > 1
    end
    
    ret_items_occurring_more_than_once.uniq()
  end
  
  def self.f_date(date)
    date.strftime("%d.%m.%y") if date
  end
  
  def self.f_date_time(date)
    date.strftime("%d.%m.%y %H:%M") if date
  end
  
  def self.set_offset(column_name, i, num_in_one_go)
    if i < num_in_one_go # return to beginning of data - came to end in last pass
      Odd.set_data(column_name, 0)
    else
      Odd.set_data(column_name, Odd.get_data(column_name) + num_in_one_go)
    end
  end
  
  def self.rank(items, key)
    ranked_items = {}
    for raw_item in items
      item = key ? raw_item[key].downcase : raw_item.downcase
      if ranked_items[item]
        ranked_items[item] += 1
      else
        ranked_items[item] = 1
      end
    end

    ranked_items.keys().sort { |x,y| ranked_items[y] <=> ranked_items[x] }
  end

  def self.rotate_hash(hash)
    rotated_hash = {}
    for key in hash.keys()
      for item in hash[key]
        if rotated_hash.has_key?(item)
          rotated_hash[item] << key
        else
          rotated_hash[item] = [key]
        end
      end
    end

    rotated_hash
  end
  
  def self.write_to_file(path, str)
    File.open(path, 'w') {|f| f.write(str) }
  end
  
  def self.ne(str)
    str && str != ""
  end
  
  def self.production?
    ENV["RAILS_ENV"] == "production"
  end
end