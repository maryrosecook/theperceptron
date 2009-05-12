class ArtistController < ApplicationController
  before_filter :admin_login_required, :only => [:remove_artist, :rename, :merge]
  
  def flag
    create_fake_user() if !logged_in?()
  
    flag = Flag.new()
    flag.reason = params[:flag][:reason]
    flag.artist_id = params[:flag][:artist]
    flag.user = current_user
    @flag_success = flag.save()
    
    render(:partial => 'flag_result')
  end
  
  def remove_artist()
    if logged_in? && current_user.admin == 1
      artist_id = params[:artist_id]
      if artist_id && artist_id != "" && artist = Artist.find(artist_id)
        if Artisting.remove(artist)
          flash[:notice] = "Artist successfully removed."
          redirect_to("/")
        else
          flash[:notice] = "Artist could not be removed."
          redirect_to("/")
        end
      end
    end
  end

  def rename()
    if logged_in? && current_user.admin == 1
      artist_id = params[:artist][:id]
      new_name = params[:artist][:name]
      artist = Artist.find(artist_id)
      if artist && new_name && new_name != ""
        existing_artist = Artist.find_for_name(new_name)
        if !existing_artist || existing_artist == artist # no name clash or is clashing w/ self (latter = cap change)
          artist.name = new_name
          artist.generate_safe_name()
          artist.save() ? @rename_result = "renamed" : @rename_result = "rename failed"
        else
          @rename_result = "exists"
        end
        render(:partial => 'artist/rename_result')
      end
    end
  end

  def elsewhere
    # record rating
    if params[:artist_id] && params[:artist_id] != "" && params[:place] && params[:place] != ""
      if artist = Artist.find(params[:artist_id])
        if params[:recommendation_id] && params[:recommendation_id] != ""
          if recommendation = Recommendation.find(params[:recommendation_id])
            create_fake_user() if !logged_in?()
            Artist::rate(current_user, artist, params[:place], recommendation.chain)
          end
        end
      end
    end

    if params[:url]
      redirect_to(params[:url])
    else
      Log::log(current_user, artist, Log::ERROR, nil, "Could redirect user to: " + params[:artist_id].to_s + " " + params[:place].to_s)
      flash[:notice] = "I'm very sorry, there wasn't enough information to redirect you."
      redirect_back_or_default("/")
    end
  end
  
  def add_other_name()
    if logged_in?() && current_user.admin == 1
      artist_id = params[:artist][:id]
      other_name_str = params[:artist][:name]
      artist = Artist.find(artist_id)
      if artist && other_name_str && other_name_str != ""
        if !Artist.find_for_name(other_name_str)
          @add_other_name_result = "added" if OtherName.new_from_adding(artist, other_name_str).save()
          render(:partial => 'artist/add_other_name_result')
        else
          @add_other_name_result = "exists"
          render(:partial => 'artist/add_other_name_result')
        end
      end
    end
  end
  
  def switch_thing
    if artist = Artist.find(params[:artist_id])
      if thing = params[:thing]
        if act = params[:act]
          artist.switch_thing(thing, act)
          artist.save()
        end
      end
    end
    
    render(:partial => 'shared/blank')
  end
  
  def show
    @logged_in = logged_in?()
    if params[:name] || params[:artist]
      name = Artist.query_to_name(params[:name] || (params[:artist] && params[:artist][:name]))
      @artist = Artist.find_for_name(name)
      
      respond_to do |format|       
        format.html
        format.xml do
          if @artist            
            render :xml => @artist.to_xml(:except =>  [:id, :path])
          else
            render :partial => 'no_artist.rxml'
          end
        end
      end
    end
  end
  
  def merge
    success = false
    begin
      artist_1 = Artist.find(params[:artist_1][:id])
      artist_2 = Artist.find_for_name(params[:artist_2][:name])
    rescue
    end
    
    if artist_1 && artist_2
      success = true if Artisting.merge(artist_1, artist_2)
    end
    
    success ? @result = "merged" : @result = "failed"
    render(:partial => "merge_result")
  end
end