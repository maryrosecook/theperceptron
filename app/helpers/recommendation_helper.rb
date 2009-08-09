module RecommendationHelper
  
  def self.get_elsewhere_strip(recommendation)
    out = ""
    if artist = recommendation.recommended_artist
      out += artist.get_myspace_url() != "" ? "<a href='#{artist.get_elsewhere_intermediary_url(Artist::MYSPACE, recommendation)}'>myspace</a> " : ""
      out += "&nbsp; " if artist.get_myspace_url() != ""
    	out += artist.get_article_url() != "" ? "<a href='#{artist.get_elsewhere_intermediary_url(Artist::WIKIPEDIA, recommendation)}'>wikipedia</a> " : ""
      out += "&nbsp; " if artist.get_article_url() != ""
    	out += artist.get_website() != "" ? "<a href='#{artist.get_elsewhere_intermediary_url(Artist::WEBSITE, recommendation)}'>website</a> " : ""
      out += "&nbsp; " if artist.get_website() != ""
    	#out += artist.get_insound_url() != "" && artist.get_amazoncom_url() != "" ? " buy on <a href='#{artist.get_elsewhere_intermediary_url(Artist::INSOUND, recommendation)}'>insound</a> or <a href='#{artist.get_elsewhere_intermediary_url(Artist::AMAZONCOM, recommendation)}'>amazon</a> " : ""
    end
    
    out
  end
  
  def self.get_sources(recommendation)
    out = "suggested by: "
  	i = 0
  	chain_links = recommendation.chain_links()
  	leading_artist = recommendation.get_starting_artist()
  	for link in chain_links
  		leading_artist == link.first_artist ? trailing_artist = link.second_artist : trailing_artist = link.first_artist
      out += "<a href='/recommendation/artist/#{leading_artist.get_safe_name()}'>#{leading_artist.name}</a>" if i > 0

      whys = []
  		link.sources().sort {|x,y| y.grade <=> x.grade }.each {|source| whys << source.why unless whys.include?(source.why) }

      j = 0
      for why in whys
  			out += " + " if j != 0
  			out += " " + why + " "
  			j += 1
  		end

      #out += "<a href='/recommendation/artist/#{trailing_artist.get_safe_name()}'>#{trailing_artist.name}</a>" if i == chain_links.length - 1
  		
  		i += 1
  		leading_artist = trailing_artist
  	end
  	
  	out
  end
end