# This file is auto-generated from the current state of the database. Instead of editing this file,
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20080803084351) do

  create_table "aphorisms", :force => true do |t|
    t.text "body"
  end

  create_table "artists", :force => true do |t|
    t.string "name",             :limit => 500
    t.string "sample_track_url", :limit => 500
    t.text   "summary"
    t.string "path",             :limit => 500
    t.string "article_title",    :limit => 500
    t.string "myspace_url",      :limit => 500
    t.string "website",          :limit => 500
    t.string "safe_name",        :limit => 500
  end

  add_index "artists", ["name"], :name => "name"
  add_index "artists", ["safe_name"], :name => "safe_name"

  create_table "artists_sub_sources", :id => false, :force => true do |t|
    t.integer "artist_id"
    t.integer "sub_source_id"
  end

  add_index "artists_sub_sources", ["artist_id"], :name => "artist_id"
  add_index "artists_sub_sources", ["sub_source_id"], :name => "sub_source_id"

  create_table "audios", :force => true do |t|
    t.text     "title"
    t.text     "artist_name"
    t.text     "body"
    t.integer  "file_upload_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "audios", ["file_upload_id"], :name => "file_upload_id"
  add_index "audios", ["user_id"], :name => "user_id"

  create_table "blog_posts", :force => true do |t|
    t.text     "title"
    t.text     "content"
    t.text     "tags"
    t.datetime "date"
    t.integer  "published"
  end

  create_table "buys", :force => true do |t|
    t.integer "artist_id"    
    t.string  "username",  :limit => 100
  end

  create_table "communiques", :force => true do |t|
    t.text     "body"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "communiques", ["user_id"], :name => "user_id"

  create_table "file_uploads", :force => true do |t|
    t.text "local_path"
  end

  create_table "flags", :force => true do |t|
    t.integer  "artist_id"
    t.integer  "user_id"
    t.text     "reason"
    t.integer  "resolved",  :default => 0
    t.datetime "time"
  end

  add_index "flags", ["artist_id"], :name => "artist_id"
  add_index "flags", ["user_id"], :name => "user_id"

  create_table "link_ratings", :force => true do |t|
    t.integer  "user_id"
    t.integer  "link_id"
    t.string   "rating",  :limit => 50
    t.datetime "time"
  end

  add_index "link_ratings", ["link_id"], :name => "link_id"
  add_index "link_ratings", ["user_id"], :name => "user_id"

  create_table "links", :force => true do |t|
    t.integer  "first_artist_id"
    t.integer  "second_artist_id"
    t.float    "grade",              :default => 0.5
    t.datetime "grade_recalculated"
  end

  add_index "links", ["first_artist_id"], :name => "first_artist_id"
  add_index "links", ["second_artist_id"], :name => "second_artist_id"
     
  create_table "links_sources", :id => false, :force => true do |t|
    t.integer "link_id"
    t.integer "source_id"
  end
    
  add_index "links_sources", ["link_id"], :name => "link_id"
  add_index "links_sources", ["source_id"], :name => "source_id"

  create_table "links_users", :id => false, :force => true do |t|
    t.integer "link_id"
    t.integer "user_id"
  end
     
  create_table "logs", :force => true do |t|
    t.integer  "user_id"
    t.integer  "item_id"
    t.string   "item_class",          :limit => 50
    t.string   "event"
    t.text     "exception_backtrace"
    t.text     "exception_message"
    t.datetime "time"
    t.text     "message"
  end
  
  create_table "mps", :force => true do |t|
    t.integer "person_id"
    t.string  "name",      :limit => 500
  end
    
  create_table "names", :force => true do |t|
    t.string  "body",           :limit => 1000
    t.integer "rank"
    t.integer "emusic_scraped",                 :default => 0
    t.integer "first_name",                     :default => 0
    t.integer "last_name",                      :default => 0
  end
    
  create_table "odds", :force => true do |t|
    t.integer "last_link_offset",                         :default => 0
    t.integer "last_myspace_bills_offset",                :default => 0
    t.integer "last_delete_bad_sample_track_urls_offset", :default => 0
    t.integer "last_updated_artist_offset",               :default => 0
    t.integer "last_lastfm_offset",                       :default => 0
  end
     
  create_table "other_names", :force => true do |t|
    t.string  "name",      :limit => 500
    t.integer "artist_id"
  end
    
  add_index "other_names", ["artist_id"], :name => "artist_id"
  add_index "other_names", ["name"], :name => "name"

  create_table "rated_artists", :force => true do |t|
    t.integer "artist_id"
    t.integer "user_id"
    t.integer "hidden",    :default => 0
    t.string  "rating"
  end
    
  add_index "rated_artists", ["artist_id"], :name => "artist_id"
  add_index "rated_artists", ["rating"], :name => "rating"
  add_index "rated_artists", ["user_id"], :name => "user_id"

  create_table "recommendations", :force => true do |t|
    t.text     "chain"
    t.float    "grade"
    t.integer  "user_id"
    t.integer  "search_artist_id"
    t.integer  "recommended_artist_id"
    t.datetime "time"
    t.integer  "user_recommendation",   :default => 0
    t.integer  "user_seen",             :default => 0
    t.integer  "saved",                 :default => 0
  end
    
  add_index "recommendations", ["recommended_artist_id"], :name => "recommended_artist_id"
  add_index "recommendations", ["search_artist_id"], :name => "search_artist_id"
  add_index "recommendations", ["user_id"], :name => "user_id"
    
  create_table "rejections", :force => true do |t|
    t.integer "artist_id"
    t.string  "thing",     :limit => 50
    t.text    "data"
  end
    
  add_index "rejections", ["artist_id"], :name => "artist_id"
  add_index "rejections", ["thing"], :name => "thing"
  create_table "searches", :force => true do |t|
    t.text     "body"
    t.integer  "result_count",     :default => 0
    t.integer  "search_artist_id"
    t.datetime "time"
    t.integer  "hand_search",      :default => 0
    t.integer  "user_id"
  end

  add_index "searches", ["search_artist_id"], :name => "search_artist_id"
  add_index "searches", ["user_id"], :name => "user_id"
    
  create_table "source_grades", :force => true do |t|
    t.integer  "source_id"
    t.integer  "artist_id"
    t.integer  "calculation_number"
    t.float    "grade"
    t.datetime "time"
  end

  add_index "source_grades", ["artist_id"], :name => "artist_id"
  add_index "source_grades", ["source_id"], :name => "source_id"
    
  create_table "sources", :force => true do |t|
    t.string "type"
    t.text   "sample"
    t.float  "grade",       :default => 0.0
    t.string "why"
    t.text   "why_verbose"
    t.string "name"
    t.text   "link"
  end
  
  create_table "sub_sources", :force => true do |t|
    t.text    "name"
    t.integer "source_id"
  end
    
  add_index "sub_sources", ["source_id"], :name => "source_id"
    
  create_table "temp_artist_associations", :force => true do |t|
    t.text    "name"
    t.text    "others"
    t.integer "source_id"
    t.integer "added",     :default => 0
  end

  add_index "temp_artist_associations", ["source_id"], :name => "source_id"

  create_table "temp_artist_meta_datas", :force => true do |t|
    t.text    "article_title"
    t.text    "summary"
    t.text    "myspace_url"
    t.text    "website"
    t.text    "sample_track_url"
    t.integer "added",            :default => 0
    t.integer "artist_id"
  end

  create_table "users", :force => true do |t|
    t.string   "username"
    t.string   "email"
    t.string   "crypted_password",             :limit => 40
    t.string   "salt",                         :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.integer  "admin",                                       :default => 0
    t.integer  "fake",                                        :default => 0
    t.string   "twitter_username",             :limit => 100
    t.integer  "automatron_twitter_subscribe",                :default => 0
    t.integer  "unsubscribed",                                :default => 0
  end
end