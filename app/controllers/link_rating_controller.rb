class LinkRatingController < ApplicationController

  def like
    rate_link(params[:artist_id], RatingPlace::LIKED)
    render(:partial => 'liked_link_rating_result')
  end
  
  def dislike
    rate_link(params[:artist_id], RatingPlace::DISLIKED)
    render(:partial => 'disliked_link_rating_result')
  end
  
  private
    
    def rate_link(artist_id, rating)
      create_fake_user() if !logged_in?()
      Artist::rate(current_user, Artist.find(params[:artist_id]), rating, params[:chain_str])
    end
end