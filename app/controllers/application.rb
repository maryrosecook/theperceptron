# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  include AuthenticatedSystem # Be sure to include AuthenticationSystem in Application Controller instead

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'fc14c6a38b8df33ca6bd3a41a941a5fe'
  
  before_filter(:login_from_cookie) # If you want "remember me" functionality, add this before_filter to Application Controller
  
  def rescue_action_in_public(exception)
    Log::log(current_user, nil, Log::ERROR, exception, nil)
    render :template => "shared/500"
  end
    
  def local_request?
    false
  end
end
