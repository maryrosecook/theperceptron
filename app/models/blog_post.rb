class BlogPost < ActiveRecord::Base  
  PUBLISHED = true
  UNPUBLISHED = false
  
  FEED_POST_COUNT = 20
  
  CAT_MAIN = "main"
  CAT_SHORT = "short"
  
  def self.recent()
    blog_posts = Array.new()
    i = 0
    for blog_post in self.find(:all, :order => 'date desc')        
      if blog_post.publishable == true && i < FEED_POST_COUNT
        blog_posts << blog_post
        i += 1
      end
    end
    
    blog_posts
  end
  
  def self.count_by_publish_state(published)
    i = 0
    for post in self.find(:all, :order => 'date desc')        
      if post.publishable == published
        i += 1
      end
    end
    i
  end
  
  def self.find_by_publish_state(published, offset, limit)
    posts = Array.new()
    
    full_i = 0
    part_i = 0
    for post in self.find(:all, :order => 'date desc')        
      if post.publishable == published
        if full_i >= offset && part_i < limit
          posts << post
          part_i += 1
        end
        full_i += 1
      end
    end
    posts
  end
  
  def publishable
    self.published == 1
  end
  
  def in_progress
    self.published == 0
  end
  
  def get_f_date()
    if self.date
      self.date.strftime("%d.%m.%y")
    end
  end
  
  def category
    if self.title && self.title != ""
      return CAT_MAIN
    else
      return CAT_SHORT
    end
  end
  
  def get_f_content()
    content = self.content.gsub(/[\n]/, '<br/>')
    content = RedCloth.new(content).to_html()
    content = content.gsub('<p>', '')
    content.gsub('</p>', '')
  end
  
  # fills in required fields
  def fill_in_blanks
    if(!self.date)
      self.date = DateTime::now()
    end
    if(!self.title)
      self.title = ""
    end
  end
end