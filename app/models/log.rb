class Log < ActiveRecord::Base #nt
  belongs_to :user
  
  CLAIM = "claim"
  SIGN_UP = "sign_up"
  ERROR = "error"
  SCRAPE = "scrape"
  EVENT = "event"
  API_UNKNOWN_FAIL = "api_unknown_fail"
  API_TIMEOUT = "api_timeout"
  NEW_MESSAGE_MAIL_SEND_ERROR = "new_message_mail_send_error"
  OUT_OF_TIME = "out_of_time"
  COMMUNIQUE = "communique"
  TWITTER_RECOMMENDATION_FAILURE = "twitter_recommendation_failure"
  USER_SUGGESTION_ERROR = "user_suggestion_error"
  
  EMAIL_ABOUT = [SIGN_UP, CLAIM, ERROR, NEW_MESSAGE_MAIL_SEND_ERROR, OUT_OF_TIME, COMMUNIQUE, USER_SUGGESTION_ERROR]
  MESSAGE_FILTERS = ["InvalidAuthenticityToken", "No route matches"]
  
  DO_LOG = true
  DO_NOT_LOG = false
  
  def self.log(user, item, event, exception, message)
    tripped_filter = false
    if exception && exception.message
      for filter in MESSAGE_FILTERS
        if exception.message.match(filter)
          tripped_filter = true
          break
        end
      end
    end
      
    if !tripped_filter && Util.production?
      log = Log.new()
      log.user_id = user.id unless !user
      log.item_id = item.id unless !item
      log.item_class = item.class unless !item
      log.event = event
      log.exception_backtrace = exception.backtrace unless !exception
      log.exception_message = exception.message unless !exception
      log.message = message unless !message
      log.time = Time.new()
      log.save()
    
      if EMAIL_ABOUT.include?(log.event)
        Mailing::deliver_log_email(log)
      end
    end
    
    Logger.new(STDOUT).error message.to_s if !Util.production? # log to console if on dev
  end
  
  def self.get_all_logs(offset, limit)
    self.find(:all, :order => 'time DESC', :offset => offset, :limit => limit)
  end
end