class RecommendationController < ApplicationController
  
  def index
    if Util.ne(params[:query]) && params[:query] != Search::SEARCH_CANNED
      query = Util::str_to_query(params[:query])
      redirect_location = "/recommendation/artist/" + query
      redirect_location += "?h=true" if params[:h] == "true"
      redirect_to(redirect_location)
    else
      @home = true
      render(:action => 'artist')
    end
  end

  def artist
    @recommending = true
    @logged_in = logged_in?()
    @flag = Flag.new_primer()
    @recommended_artist = Artist.new()
    
    search = create_search(request, params)
    if Util.ne(search.body)
      @search = search
      @found_artists = Search::search(@search.body)
      if @found_artists.length > 0 && @found_artists[0]
        @search.search_artist = @found_artists[0]
        @search.body = @search.search_artist.name if @search.search_artist.safe_name == @search.body
        @recommendations = Recommendation::recommend_for_artist(@search.search_artist, current_user)
        @search.result_count = @recommendations.length
        store_location()
      end
      
      @search.save()
    end
    
    respond_to do |format| 
      format.html
      format.xml { render :xml => @recommendations.to_xml(:include => [:recommended_artist],
                                                          :except => [:recommended_artist_id, :search_artist_id, :user_id, :id, :chain, :artist_id, :grade]) } 
    end
  end
  
  # shows all recent recommendations for a user
  def user
    @recommending = true
    @recommendations = []
    if user = User.find_by_username(params[:username])
      @web_link = "http://theperceptron.com/recommendation/user/#{user.username}"
      @recommendations = Recommendation::user_recommendations(user)
      @title = user.username + "'s recommendations"
    else
      @title = "Could not find that user"
    end
    
    respond_to do |format| 
      format.xml { render(:action => 'recommendations.rxml') } 
    end
  end
  
  # shows a few automatronically generated recommendations for a user
  def automatron
    @recommending = true
    @logged_in = logged_in?()
    @recommendations = []
    
    store_location if !@logged_in
    user = User.find_by_username(params[:username])
    user = current_user if !user && logged_in?() && current_user.real?()
    if user
      @web_link = "http://theperceptron.com/recommendation/automatron/#{user.username}"
      @recommendations = Recommendation::automatron(user)
      @title = user.username + "'s automatron recommendations"
    else
      @title = "Could not find that user"
    end
    
    respond_to do |format| 
      format.xml { render(:layout => false, :action => 'recommendations.rxml') }
      format.html
    end
  end
  
  def playlist()
    @playlist = true
    @recommendations = []
    if @logged_in = logged_in?()
      @flag = Flag.new_primer()
      @recommendations = Recommendation.get_saved(current_user)
    end
    
    respond_to do |format| 
      format.m3u { render(:layout => false, :action => 'playlist.m3u.erb') } if @recommendations
      format.html { render(:action => 'playlist.rhtml') }
    end
  end
  
  def show
    @logged_in = logged_in?()
    @recommendation = Recommendation.find_by_id(params[:id])
  end
  
  def add_user_suggestion()
    search_artist_found = false    
    recommended_artist_name = params[:recommended_artist][:name] if params[:recommended_artist]
    search_artist = Artist.find(params[:search][:search_artist_id]) if params[:search] && params[:search][:search_artist_id]

    if search_artist
      if recommended_artist_name && recommended_artist_name != ""
        create_fake_user() if !logged_in?()
        recommended_artist = Artist.get_or_create(recommended_artist_name)
        source = Source::get(Source::USER_SUGGESTIOM_SOURCE)
        new_rec = source.add_user_suggestion(search_artist, recommended_artist, current_user)
        if new_rec
          @result = "Thanks very much. <strong>#{recommended_artist.name}</strong> were added to the recommendations."
        else
          @result = "I already had that recommendation, but thanks anyway."
        end
      else
        @result = "Please enter the name of an artist."
      end
    else
      Log::log(current_user, nil, Log::USER_SUGGESTION_ERROR, nil, "User tried to suggest, but couldn't get search_artist_id")
      @result = "Sorry, there was an error. It has been reported."
    end
    
    render(:partial => "add_user_suggestion_result")
  end
  
  def switch_save_state()
    if recommendation = Recommendation.find(params[:recommendation_id])
      create_fake_user() if !logged_in?()
      recommendation.switch_save_state(params[:new_state])
      recommendation.user = current_user
      recommendation.save()
      
      # record 'rating'
      Artist::rate(current_user, recommendation.recommended_artist, RatingPlace::PLAYLIST, recommendation.chain)
    end
    render(:partial => 'saved_recommendation_result')
  end
  
  def saved_xml
    @recommendations = Recommendation.get_saved(current_user)
    render :layout => false
  end
  
  private
  
    def create_search(request, params)
      hand_search = false # true if search done by user actually writing the words, rather than clicking on an artist name
      hand_search = true if params[:h] == "true"
      search_body = Artist::query_to_name(params[:query]) if params[:query]

      Search.new_from_searching(current_user ? current_user : nil, search_body, nil, 0, hand_search)
    end
    
    def logged_in_and_real()
      if !(logged_in?() && current_user.real?())
        flash[:notice] = "You must <a href='/account/login'>login</a> or <a href='/account/signup'>sign up</a> to do that."
        redirect_to("/")
      end
    end
end