class LogController < ApplicationController
  before_filter :admin_login_required
  
  def list
    if !params[:offset] || params[:offset] == ""
      @offset = 0
    else
      @offset = params[:offset]
    end

    @logs = Log.get_all_logs(@offset, 100)
  end
  
  def show
    @log = Log.find(params[:id])
  end
end