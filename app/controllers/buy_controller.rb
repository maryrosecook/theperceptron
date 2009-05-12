class BuyController < ApplicationController
  
  ARTIST_FREQ = 20
  ARTIST_LINK_FREQUENCY = 20
  
  def scrape
    for name in Name.find(:all, :conditions => "emusic_scraped != 1", :order => 'id ASC')
      if name.body && name.body != ""
        url = "http://www.emusic.com/profile/ajax/downloads/artists.html?nickname=" + name.body
        if res = APIUtil::get_request(url)
          if res.match(/Begins With/i)
            res.each {|line|
              if line.match(/\<\/li\>/)
                artist_name = line.match(/\>[^\<]*\</).to_s.gsub(/\>/, "").gsub(/\</, "")
                if artist_name && artist_name != ""
                  if artist = Artist.find_for_name(artist_name)
                    Buy.new_from_scrape(artist, name.body).save()
                  end
                end
              end
            }
          end
        end
        
        #sleep 5 * rand()
      end
      
      name.emusic_scraped = 1
      name.save()
    end
  end
  
  def cluster()
    buys = Buy.find(:all, :offset => 200001, :limit => 200000, :order => "id")

    # collection hash of artists and the user libraries they appear in
    artist_ids_and_usernames = {}
    for buy in buys
      artist_ids_and_usernames[buy.artist_id] = [] if !artist_ids_and_usernames.has_key?(buy.artist_id)
      artist_ids_and_usernames[buy.artist_id] << buy.username
    end

    # remove all duplicate users from hash.
    for artist_id in artist_ids_and_usernames.keys()
      unique_usernames = artist_ids_and_usernames[artist_id].uniq()
      if unique_usernames.length >= ARTIST_FREQ 
        artist_ids_and_usernames[artist_id] = unique_usernames
      else
        artist_ids_and_usernames.delete(artist_id)
      end
    end
    
    # create new hash of transposed usernames and artists
    usernames_and_artist_ids = Util::rotate_hash(artist_ids_and_usernames)
    
    # create pairs of users who both like the same artist
    candidate_user_pairs = []
    for artist_id in artist_ids_and_usernames.keys()
      artist_usernames = artist_ids_and_usernames[artist_id]
      for username1 in artist_usernames
        for username2 in artist_usernames
          break if username1 == username2
          candidate_user_pairs << [username1, username2]
        end
      end
    end

    candidate_user_pairs = candidate_user_pairs.uniq()

    # find intersections of candidate user pair artist libraries
    intersections = []
    for candidate_user_pair in candidate_user_pairs
      intersection = usernames_and_artist_ids[candidate_user_pair[0]] & usernames_and_artist_ids[candidate_user_pair[1]]
      intersections << intersection if intersection
    end    
    
    # whizz through intersections and connect all artists inside each one.
    # Count freq of connections for each artist pair.
    @artist_links = {}
    for artist_ids in intersections
      for artist_id1 in artist_ids
        for artist_id2 in artist_ids
          break if artist_id1 == artist_id2
          link = [artist_id1, artist_id2]
          if @artist_links.has_key?(link)
            @artist_links[link] += 1
          else
            @artist_links[link] = 1
          end
        end
      end
    end
    
    # remove all artist connections that don't occur at least ARTIST_LINK_FREQUENCY times
    @artist_links.keys().each { |artist_link| @artist_links.delete(artist_link) if @artist_links[artist_link] < ARTIST_LINK_FREQUENCY }
    
    @artist_ids_and_names = {}
    for artist_id in artist_ids_and_usernames.keys()
      @artist_ids_and_names[artist_id] = Artist.find(artist_id).name
    end
    
    source = Source::get(Source::EMUSIC_SOURCE)    
    for artist_link in @artist_links.keys()
      main_artist = @artist_ids_and_names[artist_link[0]]
      others = @artist_ids_and_names[artist_link[1]]
      TempArtistAssociation::new_from_associating(@artist_ids_and_names[artist_link[0]], @artist_ids_and_names[artist_link[1]], source).save()
    end
    #TempArtistAssociation.convert_temp_artist_associations()

    @ranked_artist_links = @artist_links.keys().sort { |x,y| @artist_links[y] <=> @artist_links[x] }
  end
end