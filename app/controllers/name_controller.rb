class NameController < ApplicationController
  
  def add
    i = 0
    j = 0
    existing_names = []
    Name.find(:all).each { |name| existing_names << name.body }
    File.open("/Users/maryrosecook/Desktop/namesandcommonwords1.txt").each { |line|
      if line && line != "" && line.match(/\w+/)
        name = line.downcase
        if !existing_names.include?(name)
          rank = 1
          Name.new_with_rank(name, rank).save() if rank && rank != "" && name && name != ""
          Logger.new(STDOUT).error i.to_s
          i += 1
        end
      end
    }
    
    raise j.to_s
  end
  
  def names_to_file
    path = "/Users/maryrosecook/Desktop/namesandcommonwords.txt"
    i = 0
    usernames = []
    for name in Name.find(:all, :order => 'body')
      username = name.body.gsub(/\n/, "")
      usernames << username if !usernames.include?(username)
      Logger.new(STDOUT).error i.to_s
      i += 1
    end
    
    str = ""
    for username in usernames
      str += "\n" if i > 0
      str += username
    end
    
    Util::write_to_file(path, str)
  end
end