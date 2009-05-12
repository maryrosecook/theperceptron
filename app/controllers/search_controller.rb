class SearchController < ApplicationController
  before_filter :admin_login_required, :except => [:recent]
  
  def list
    if !params[:offset] || params[:offset] == ""
      @offset = 0
    else
      @offset = params[:offset]
    end

    @searches = Search.find_hand_searches_admin(@offset, 20)
  end
  
  def recent
    limit = Search::DEFAULT_RECENT_SEARCHES_COUNT
    limit = params[:limit] if params[:limit]
    limit = Search::MAX_RECENT_SEARCHES_COUNT if limit.to_i > 200
    offset = 0
    offset = params[:offset] if params[:offset]

    @searches = Search.get_all_searches(offset, limit)
    respond_to do |format| 
      format.xml { render(:layout => false, :action => 'recent.rxml') }
    end
  end
end