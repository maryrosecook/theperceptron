class FlagController < ApplicationController
  before_filter :admin_login_required

  def index
    render(:action => 'list')
  end

  def list
    @flagging = true
    @logged_in = logged_in?()
    if !params[:offset] || params[:offset] == ""
      @offset = 0
    else
      @offset = params[:offset]
    end

    @unresolved_flags = Flag.get_unresolved_paged(@offset, 20)
  end
  
  def resolve
    if flag = Flag.find_by_id(params[:flag_id])
      flag.resolved = 1
      flag.save()
    end
    
    render(:partial => 'shared/blank')
  end
end