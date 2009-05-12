class LinkController < ApplicationController

  def destroy_user_suggestion()
    if link_id = params[:link_id]
      if link = Link.find(link_id)
        user_suggestion_source = Source.get(Source::USER_SUGGESTIOM_SOURCE)
        if link.sources().include?(user_suggestion_source)
          link.sources().delete(user_suggestion_source)
          link.users().clear
          @result = "x" if link.save()
        else
          @result = "No US source"
        end
      else
        @result = "No find link"
      end
    else
      @result = "No find link"
    end
    
    render(:partial => 'link/destroy_user_suggestion_result')
  end
end