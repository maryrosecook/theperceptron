require 'net/imap'

class Mailing < ActionMailer::Base
  COMMUNICATION_EMAIL_ADDRESS = "communication@theperceptron.com"
  TEST_RECIPIENT_EMAIL_ADDRESS = "contact@theperceptron.com"
  ERROR_LOG_EMAIL_ADDRESS = "contact@theperceptron.com"
  
  # sends out email to recipient of new message
  # def new_message_email(message)
  #   message_sender = message.user
  #   user_to_email = message.conversation.get_other_user(message_sender)
  #   
  #   # compose email components
  #   recipients ENV["RAILS_ENV"] == "development" ? TEST_RECIPIENT_EMAIL_ADDRESS : user_to_email.email
  #   from COMMUNICATION_EMAIL_ADDRESS
  #   reply_to = COMMUNICATION_EMAIL_ADDRESS
  #   subject "New jadorable message from #{message_sender.username}"
  # 
  #   body[:user_to_email] = user_to_email
  #   body[:message_sender] = message_sender
  #   body[:message_body] =  message.body
  #   body[:conversation] = message.conversation
  #   body[:site_url] = Util::get_site_url()
  #   body[:real_recipient] = user_to_email.email unless ENV["RAILS_ENV"] == "production"
  # end

  # emails me when there is an error
  def log_email(log)
    # compose email components
    recipients ERROR_LOG_EMAIL_ADDRESS
    from COMMUNICATION_EMAIL_ADDRESS
    reply_to = COMMUNICATION_EMAIL_ADDRESS
    subject "Logged: #{log.event}."

    body[:current_user] = log.user unless !log.user
    body[:item_id] = log.item_id unless !log.item_id
    body[:item_class] = log.item_class unless !log.item_class
    body[:event] = log.event unless !log.event
    body[:exception_backtrace] = log.exception_backtrace unless !log.exception_backtrace
    body[:exception_message] = log.exception_message unless !log.exception_message
    body[:message] = log.message unless !log.message
    body[:time] = log.time unless !log.time
  end
  
  # pull in emails from communication@jadorable.com
  # def self.poll_for_communication_emails()
  #   config = YAML.load_file("#{RAILS_ROOT}/config/communication_email.yml")[ENV["RAILS_ENV"]]
  #   delete = ENV["RAILS_ENV"] == "production"
  #   poll_for_emails(config, delete)
  # end
  
  # pulls in emails from passed email address and server via imap
  # def self.poll_for_emails(config, delete)
  #   emails = []
  #   imap = Net::IMAP.new(config[:server], config[:port], true)
  #   imap.login(config[:username], config[:password])
  #   
  #   imap.examine('INBOX')
  #   imap.search(['ALL']).each do |message_id|
  #     msg = imap.fetch(message_id,'RFC822')[0].attr['RFC822']
  #     parsed_msg = TMail::Mail.parse(msg)
  #     
  #     # extract message data and save in db
  #     email = Email.new()
  #     email.subject = parsed_msg.subject
  #     email.body = parsed_msg.body
  #     email.dealt_with = false
  #     email.save()
  #     
  #     emails << email
  #     
  #     imap.store(message_id, "+FLAGS", [:Deleted]) unless !delete # delete email from server
  #   end
  #   
  #   imap.close
  #   
  #   emails
  # end
end
