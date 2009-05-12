class TempArtistAssociation < ActiveRecord::Base
  belongs_to :source

  CONVERT_IN_ONE_GO = 1800

  def self.new_from_associating(name, others, source)
    temp_artist_association = nil
    if name && others && source
      temp_artist_association = self.new()
      temp_artist_association.name = name
      temp_artist_association.others = others
      temp_artist_association.source = source
      temp_artist_association.added = 0
    end

    temp_artist_association
  end
  
  def self.already_saved?(name, source)
    self.find(:first, :conditions => "name = \"" + Util::esc_for_speech(name) + "\" && source_id = #{source.id}")
  end
  
  def self.find_artists_not_added()
    self.find(:all, :conditions => "added = 0 && others IS NOT NULL && others != ''", :limit => CONVERT_IN_ONE_GO)
    
  end
  
  # adds and saves all non added temp_artist_association artists and links w/ others
  def self.convert_temp_artist_associations()
    i = 0
    Log::log(nil, nil, Log::EVENT, nil, "Starting a TempArtistAssociation conversion.")
    for temp_artist_association in TempArtistAssociation::find_artists_not_added()
      if temp_artist_association.others && temp_artist_association.others.strip() != "" # only proceed if there are others
        main_artist_name = temp_artist_association.name
        if main_artist_name && main_artist_name != ""
          main_artist = Artist.get_or_create(main_artist_name)
        
          if main_artist.save()
            i += 1
            #log.error(j.to_s + " " + main_artist.name.to_s)
            # create other artist and link w/ main artist and save both
            for other_artist_name in temp_artist_association.others.split(", ")
              if other_artist_name && other_artist_name != ""
                other_artist = Artist.get_or_create(other_artist_name)
                if other_artist.save()
                  i += 1
                  Link::get_or_create(main_artist, other_artist, temp_artist_association.source).save() # create/get link and save
                end
              end
            end
          end
        end
      end
      
      # save that temp_artist_association has been added
      temp_artist_association.added = 1
      temp_artist_association.save()
    end
    Log::log(nil, nil, Log::EVENT, nil, "Finishing a TempArtistAssociation conversion.  Added #{i} artists.")
    
    i
  end
  
  # swaps amp and ' entities for their real counterparts
  def self.scrub(str)
    Util::scrub_fastidious_entities(str).gsub(/<\/p>/, "").gsub(/<p>/, "").gsub(/<br \/>/, "")
  end
end