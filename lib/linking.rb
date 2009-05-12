module Linking
  
  # takes chain and returns array of links
  def self.chain_to_links(chain)
    links = []
    previous_item = nil
    current_item = nil
    for item in chain
      current_item = item
      if current_item && previous_item # not at beginning of chain
        link = Link.find_by_artists(previous_item, current_item)
        links << link unless !link
      end
      
      previous_item = current_item
    end
    
    links
  end
  
  def self.get_starting_artist(chain)
    starting_artist = nil
    starting_artist = Artist.find_by_id(chain[0]) if chain.length > 0

    starting_artist
  end
end