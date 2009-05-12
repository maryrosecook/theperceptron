class LabController < ApplicationController

  def index
  end

  def voxpomp
    if request.post? # perform a search
      if Util.ne(params[:search])
        @statements = Twfying.search_debates(params[:search], params[:mp_name])
        for statement in @statements
          statement[:news] = Daylifeing.search(params[:search], statement[:date])
          statement[:news_url] = Yahoo.get_archive_url(params[:search], statement[:date]) if statement[:news].length == 0
        end
      else
        @no_search = true
      end
    end
  end

  def where_to_live()
    if request.post?()
      redirect_to("/lab/where_to_live/" + params[:username]) if params[:username]
    elsif params[:id]
      @cities_artists = {}
      @username = params["id"]

      i = 0
      for artist_name in WhereToLive::get_favourite_artists(@username)
        #RAILS_DEFAULT_LOGGER.error(i.to_s + " " + artist_name.to_s)
        for city in WhereToLive::get_artist_event_cities(artist_name)
          if city
            city = city.gsub(/,.*/, "")

            if @cities_artists.has_key?(city)
              @cities_artists[city] << artist_name if !@cities_artists[city].include?(artist_name)
            else
              @cities_artists[city] = [artist_name]
            end
          end
        end
        
        i += 1
      end
      
      @sorted_cities = @cities_artists.keys().sort { |x,y| @cities_artists[y].length <=> @cities_artists[x].length }
    end
  end
  
  def lastfm_artist_page
    if params[:artist_name] && params[:artist_name] != ""
      redirect_to(WhereToLive::get_artist_url(params[:artist_name]))
    end
  end
  
  def load_mps
    Twfying.read_mp_xml()
  end
end