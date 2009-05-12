require 'digest/sha1'

class User < ActiveRecord::Base
  has_many :link_ratings
  has_many :searches
  has_many :rated_artists
  has_many :search_results
  has_many :communiques
  has_and_belongs_to_many :links
  
  attr_accessor :password, :password_confirmation, :temp_password # Virtual attribute for the unencrypted password
  
  validates_length_of       :username, :within => 1..100
  validates_length_of       :email,    :within => 1..100
  validates_format_of       :email, :with => /\A([\w\.\-\+]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
  validates_presence_of     :username, :email
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 1..100, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_uniqueness_of   :username, :email, :case_sensitive => false
  before_save :encrypt_password

  def self.get_real()
    self.find(:all, :conditions => "fake != 1")
  end
  
  def self.get_fake()
    self.find(:all, :conditions => "fake = 1")
  end

  def real?()
    self.fake != 1
  end
  
  def admin?()
    self.admin == 1
  end

  def self.get_latest(limit)
    self.find(:all, :conditions => 'fake = 0', :order => 'created_at DESC', :limit => limit)
  end

  # returns users who are due a recommendation generation
  def self.find_with_recommendations_due(recommendation_generation_interval)
    users_with_recommendations_due = []
    for user in get_real()
      last_recommendation = Recommendation::get_last(user)
      if !last_recommendation || Time.new().tv_sec - last_recommendation.time.tv_sec > recommendation_generation_interval
        users_with_recommendations_due << user
      end
    end
    
    users_with_recommendations_due
  end

  def self.new_fake()
    fake_user = self.new()
    fake_user.email = "fake"
    fake_user.create_username()
    fake_user.email = fake_user.username
    fake_user.fake = 1

    fake_user
  end
  
  def has_flagged?(artist)
    Flag.flagged?(self, artist)
  end

  def has_liked?(artist)
    RatedArtist.has?(self, artist, RatingPlace::LIKED)
  end

  def has_disliked?(artist)
    RatedArtist.has?(self, artist, RatingPlace::DISLIKED)
  end

  # creates a unique username based on user's email
  def create_username() #t
    email_username = self.email.gsub(/(\A([\w\.\-\+]+))@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, "\\1")
    email_username = email_username.gsub(/\W/, "")
    username_try = email_username
    
    i = 1
    found_unique_username = false
    while(!found_unique_username)
      if User.unique_username?(nil, username_try)
        found_unique_username = true
      else
        username_try = email_username + i.to_s
      end
      i += 1
    end
    
    self.username = username_try
  end

  # returns true if passed username is unique
  def self.unique_username?(user, username) #t
    unique = false
    if user # user already created so exclude them from search
      unique = self.find(:all, :conditions => "id != #{user.id} && username = '#{username}'").length == 0
    else
      unique = !User.find_by_username(username)
    end
    
    unique
  end

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(username, password) #nt
    u = self.find_user(username) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  # find user by checking email and username
  def self.find_user(username) #nt
    u = find_by_email(username)
    if !u
      u = find_by_username(username)
    end
    u
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    self.remember_token_expires_at = 2.weeks.from_now.utc
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end

  protected
    # before filter 
    def encrypt_password
      return if password.blank? || password != password_confirmation
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{username}--") if !self.salt
      self.crypted_password = encrypt(password)
    end
    
    def password_required?
      crypted_password.blank? || !password.blank?
    end
end