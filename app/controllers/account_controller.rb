class AccountController < ApplicationController
  before_filter :login_from_cookie

  def claim()
    if logged_in? && current_user.fake == 1
      if request.post?
        if user_to_claim = current_user
          user_to_claim.fake = 0
          user_to_claim.email = params[:user][:email]
          user_to_claim.create_username()
          user_to_claim.password = params[:user][:password]
          user_to_claim.password_confirmation = params[:user][:password_confirmation]

          if user_to_claim.save()
            Log::log(current_user, nil, Log::CLAIM, nil, "Success")
            flash[:notice] = "User claimed and logged in."
            redirect_to("")
          else
            Log::log(current_user, nil, Log::CLAIM, nil, "Fail")
            flash[:notice] = "Could not claim user."
          end
        end
      else
        current_user.email = ""
        @user_to_claim = current_user
      end
    else
      flash[:notice] = "No user to claim."
      redirect_to("")
    end
  end

  def signup
    @user = User.new(params[:user])
    return unless request.post?
    @user.create_username()
    @user.save!
    self.current_user = @user
    Log::log(current_user, nil, Log::SIGN_UP, nil, "Success")
    redirect_back_or_default("")
    flash[:notice] = "Signed up and logged in."
  rescue ActiveRecord::RecordInvalid
    Log::log(current_user, nil, Log::SIGN_UP, nil, "Fail")
    flash[:notice] = "Errors.  Please correct."
    render :action => 'signup'
  end

  def email_monitor
    text = CGI::unescape(Util::parse_js_response(request))    
    empty_str = text == ""
    valid_email = text =~ /\A([\w\.\-\+]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
    valid = valid_email

    if valid_email
      if User.find_user(text)
        render(:partial => 'monitor_existing_user')
      else
        render(:partial => 'monitor_valid')
      end
    else
      render(:partial => 'monitor_invalid')
    end
  end
  
  def password_monitor()
    text = CGI::unescape(Util::parse_js_response(request))
    if text.length > 0 && text.length < 101
      render(:partial => 'monitor_valid')
    else
      render(:partial => 'monitor_invalid')
    end
  end
  
  def password_confirmation_monitor()
    user_password = params[:user_password]
    user_password_confirmation = params[:user_password_confirmation]
    if user_password && user_password_confirmation && user_password == user_password_confirmation && user_password_confirmation.length > 0 && user_password_confirmation.length < 101
      render(:partial => 'monitor_valid')
    elsif user_password != user_password_confirmation
      render(:partial => 'monitor_must_match')
    else
      render(:partial => 'monitor_invalid')
    end
  end

  def login
    return unless request.post?
    @email = params[:user][:email]
    self.current_user = User.authenticate(params[:user][:email], params[:user][:password])
    if logged_in?
      self.current_user.remember_me
      cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
      flash[:notice] = "Logged in."
      if current_user.admin == 1
        redirect_to(:controller => 'admin')
      else
        redirect_back_or_default("")
      end
    else
      flash[:notice] = "Incorrect email or password."
    end
  end
  
  def logout
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    session[:user] = nil
    session[:return_to] = nil
    flash[:notice] = "Logged out."
    redirect_back_or_default("")
  end
end