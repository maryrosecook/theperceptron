class AdminController < ApplicationController
  before_filter :admin_login_required
  
  TEMP_ARTIST_META_DATAS_TO_GATHER_IN_ONE_GO = 10000
  
  def index
    redirect_to(:action => 'stats')
  end
  
  def stats
    @artists = Artist.count()
    @artist_sample_track_urls = Artist.count_not_null_not_empty("sample_track_url")
    @artist_summaries = Artist.count_not_null_not_empty("summary")
    @artist_websites = Artist.count_not_null_not_empty("website")
    @artist_myspace_urls = Artist.count_not_null_not_empty("myspace_url")
    @artist_sample_track_urls_percentage = ((@artist_sample_track_urls / @artists.to_f) * 100).round()
    @artist_summaries_percentage = ((@artist_summaries / @artists.to_f) * 100).round()
    @artist_websites_percentage = ((@artist_websites / @artists.to_f) * 100).round()
    @artist_myspace_urls_percentage = ((@artist_myspace_urls / @artists.to_f) * 100).round()
    @links = Link.count()
    @linkage = (@links.to_f / @artists.to_f).to_s[0..4]
    
    @link_grade_lag = (Time.new().tv_sec - Link.find(:first, :conditions => 'grade_recalculated IS NOT NULL', :order => 'grade_recalculated ASC').grade_recalculated.tv_sec) / 60 / 60 # age of least recently calculated link grade
    @source_grades_last_recalculated = SourceGrade.find(:first, :order => 'time DESC').time # date of most recently calc
    
    @rated_artists = RatedArtist.count()
    @suggestions = UserSuggestionSource::get_all(0, 99999999999999999).length
    
    @user_fakes = User.get_fake().length
    @user_reals = User.get_real().length
    @users_latest = User.get_latest(5)
    
    @flags = Flag.count()
    @flag_unresolved = Flag.get_unresolved().length
    
    @searches = Search.count(:conditions => 'hand_search = 1')
  end
  
  def data
  end
  
  def maintenance
  end
  
  def generate_user_recommendations()
    i = Recommendation::generate_user_recommendations()
    flash[:notice] = "#{i} user recommendations added."
    redirect_to(:action => 'data')
  end
  
  def scrape_epitonic()
    i = 0    
    begin
      i += EpitonicSimilarSource::scrape(nil, Source::NO_RENEW, nil)
      i += EpitonicOtherSource::scrape(nil, Source::NO_RENEW, nil)
    rescue Timeout::Error
    end
    
    flash[:notice] = "#{i} artists added."
    redirect_to(:action => 'data')
  end
  
  def scrape_lastfm()
    i = LastfmSource::scrape()
    flash[:notice] = "#{i} artists scraped from last.fm source."
    redirect_to(:action => 'data')
  end
  
  def scrape_myspace_band_friends()
    trencher = Artist.find_by_name("strawberry fair")
    i = MyspaceBandFriendsSource::scrape(nil, Source::RENEW, 100)
    flash[:notice] = "#{i} artists scraped from Myspace band friends source."
    redirect_to(:action => 'data')
  end
  
  def scrape_hype_machine_blogs()
    i = HypeMachineBlogSource.scrape()
    flash[:notice] = "#{i} artists scraped."
    redirect_to(:action => 'data')
  end
  
  def scrape_tiny_mix_tapes_reviews()
    i = TinyMixTapesSource.scrape()
    flash[:notice] = "#{i} artists scraped."
    redirect_to(:action => 'data')
  end
  
  def recalculate_link_grades()
    i = Grading::recalculate_link_grades()
    flash[:notice] = "#{i} link grades recalculated."
    redirect_to(:action => 'data')
  end
  
  def source_grades
    if params[:recalculate]
      SourceGrade::recalculate_source_grades()
      flash[:notice] = "Source grades recalculated."
      redirect_to(:action => 'source_grades')
    else
      @extras = params[:extras] == "true"
      @sources = Source.find(:all).sort {|x,y| y.grade() <=> x.grade() }
    end
  end
  
  def artist
  end
  
  def update_artist_details()
    i = Artisting.update_artist_details()
    flash[:notice] = "Data updated for #{i} artists."
    redirect_to(:action => 'artist')
  end
  
  def update_wikipedia_label_artists()
    i = WikipediaLabelSource::update()
    flash[:notice] = "#{i} label artists added."
    redirect_to(:action => 'data')
  end
  
  def convert_temp_artist_associations()
    i = TempArtistAssociation::convert_temp_artist_associations()
    flash[:notice] = "#{i} artists added."
    redirect_to(:action => 'artist')
  end
  
  def gather_temp_artist_meta_datas()
    i = TempArtistMetaData::gather_temp_artist_meta_datas(0, TEMP_ARTIST_META_DATAS_TO_GATHER_IN_ONE_GO)
    flash[:notice] = "Meta data gathered for #{i} artists."
    redirect_to(:action => 'artist')
  end
  
  def convert_temp_artist_meta_datas()
    i = TempArtistMetaData::convert_temp_artist_meta_datas()
    flash[:notice] = "#{i} artists updated."
    redirect_to(:action => 'artist')
  end
  
  def add_aphorism()
    if request.post?()
      aphorism = Aphorism.new(params[:aphorism])
      aphorism.save()
      flash[:notice] = "Aphorism added."
      redirect_to(:action => 'data')
    else
      @aphorism = Aphorism.new()
    end
  end
  
  def generate_safe_names()
    i = 0
    for artist in Artist.find(:all, :conditions => "safe_name IS NULL || safe_name = ''")
      artist.generate_safe_name()
      artist.save()
      i += 1
    end
    
    flash[:notice] = "#{i} names generated."
    redirect_to(:action => 'artist')
  end
  
  def user_suggestions()
    if !params[:offset] || params[:offset] == ""
      @offset = 0
    else
      @offset = params[:offset]
    end

    @links = UserSuggestionSource::get_all(@offset, 20)
  end
  
  def delete_bad_myspace_urls()
    i = Artisting::delete_bad_myspace_urls()
    flash[:notice] = "#{i} bad myspace urls dealt with."
    redirect_to(:action => 'artist')
  end
  
  def delete_bad_sample_track_urls()
    i = Artisting::delete_bad_sample_track_urls()
    flash[:notice] = "#{i} sample track urls dealt with."
    redirect_to(:action => 'artist')
  end
  
  def capitalise_all_band_names
    for artist in Artist.find(:all)
      artist.name = Util::cap_the_bitch(artist.name)
      artist.save()
      Logger.new(STDOUT).error(artist.name)
    end
    flash[:notice] = "Capital."
    redirect_to(:action => 'artist')
  end
  
  def write_a_log
    begin
      1/0
    rescue ZeroDivisionError => exception
      Log::log(current_user, nil, Log::ERROR, exception, "Hi Mary.  This is a test error.")
    end
  end
end