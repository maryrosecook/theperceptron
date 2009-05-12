class UserSuggestionSource < Source

  def add_user_suggestion(search_artist, recommended_artist, user)
    recommended_artist.save()
    link = Link::get_or_create(search_artist, recommended_artist, self)
    new_rec = true
    new_rec = false if link.id
    link.users() << user if !link.users().include?(user)
    link.save()
    
    new_rec
  end
  
  def self.get_all(offset, limit)
    user_suggestion_links = []
    links_users = ActiveRecord::Base.connection.execute("SELECT * FROM links_users
                                                         ORDER BY link_id DESC
                                                         LIMIT #{offset}, #{limit};")
    while row = links_users.fetch_row() do
      link_id = row[0]
      user_suggestion_links << Link.find(link_id)
    end
    links_users.free()

    user_suggestion_links
  end
end