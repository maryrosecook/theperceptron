class HomeController < ApplicationController
  
  def liked_artists
  end
  
  def new_features
  end
  
  def about
  end
  
  def contact
  end
  
  def recommendation_sources
    recommendation_sources = []
    @sources = []
    for source in Source.find(:all)
      @sources << source if !recommendation_sources.include?(source.why)
      recommendation_sources << source.why
    end
  end
  
  def api
  end
  
  def stats
    @sources = Source.find(:all)
    @most_searched_bands_this_week = Stating::most_searched_bands_this_week()
    @most_searched_bands_last_week = Stating::most_searched_bands_a_week_ago()
    @sources = Source.find(:all, :order => 'grade DESC')
  end
end