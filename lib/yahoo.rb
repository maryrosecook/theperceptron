require 'net/http'

class Yahoo

  DEFAULT_RUN_QUERY_SLEEP = 8
  
  BASE_NEWS_URL = "http://search.yahooapis.com/NewsSearchService/V1/newsSearch?results=50&language=en&appid="
  
  def self.get_artist_myspace_url(artist, sleep_time)
    url = "" # if something goes wrong, just pass back empty string and fill it into record
    xml = self.run_query(artist.name + " myspace", 1, sleep_time)
    xml.elements.each('ResultSet/Result/Url') do |url_element|
      possible_url = url_element.text()
      url = possible_url if possible_url.match(/myspace/) # check url at least contains myspace
      break
    end
    
    url
  end
  
  def self.run_query(query, num_results, in_sleep_time)
    url = "http://search.yahooapis.com/WebSearchService/V1/webSearch?appid=#{Configuring.get('yahoo_application_id')}&query=#{query}&results=#{num_results}"
    body = APIUtil::get_request(url)
    in_sleep_time ? sleep_time = in_sleep_time : sleep_time = DEFAULT_RUN_QUERY_SLEEP
    sleep(sleep_time)
    xml = APIUtil::response_to_xml(body)
  end
  
  def self.get_news(query, date)
    items = []
    total_results_available = 3
    start = 1
    total_results_available = extract_newa_results(items, query, date, start)

    return items
  end
  
  def self.extract_newa_results(items, query, date, start)
    url = BASE_NEWS_URL + Configuring.get('yahoo_application_id')
    url += "&order=date&query=" + query
    url += "&start=" + start.to_s
    body = APIUtil::get_request(url)
    xml = APIUtil::response_to_xml(body)
    
    xml.elements.each('ResultSet/Result') do |data|
      story_time = Time.at(data.elements["PublishDate"].text.to_i)
      date = date.to_date
      if story_time.year == date.year && story_time.mon == date.mon
        item = {}
        item[:title] = data.elements["Title"].text
        item[:url] = data.elements["Url"].text
        items << item
        break if items.length > 2
      end
    end

    return xml.root ? xml.root.attributes['totalResultsAvailable'] : 0
  end
  
  def self.get_archive_url(query, date)
    url_query = query.gsub(/ /, "+")
    url_year = date.to_date.strftime("%Y")
    url_mon = date.to_date.strftime("%m")
    return "http://news.google.com/archivesearch?as_q=#{url_query}&num=10&hl=en&btnG=Search+Archives&as_epq=&as_oq=&as_eq=&ned=us&as_user_ldate=#{url_year}%2F#{url_mon}&as_user_hdate=#{url_year}%2F#{url_mon}&lr=&as_src=&as_price=p0&as_scoring="
  end
end