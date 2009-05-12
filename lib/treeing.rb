module Treeing
  @closest_nodes = nil
  @unexplored_nodes = []
  @num_best_nodes = nil
      
  # get very closest MATCHING_NUM_BEST_NODES words connected to passed word
  def self.get_closest_nodes(user, value, num_closest_nodes)
    get_connected_nodes(user, value, num_closest_nodes)
  end
  
  # get words connected to passed word, up to passed limit
  def self.get_connected_nodes(user, value, in_num_best_nodes)
    @closest_nodes = []
    @unexplored_nodes = []
    @num_best_nodes = in_num_best_nodes
    
    @unexplored_nodes << TreeNode.new(value, nil, nil, [], Artist)
    i = 0
    while i < @unexplored_nodes.length() && @closest_nodes.length() < @num_best_nodes
      gen_tree(user, @unexplored_nodes[i])
      i += 1
    end

    @closest_nodes
  end

  private
    # travels down words linked to node and adds on new nodes
    def self.gen_tree(user, node)
      children = get_children(node)
      children_limit = [children.length, Recommendation::MAX_CHILDREN_TO_EXPLORE].min() - 1
      for child_node in children[0..children_limit]
        if !already_in_nodes?(@closest_nodes, child_node)
          @closest_nodes << child_node
          @unexplored_nodes << child_node if !already_in_nodes?(@unexplored_nodes, child_node) && (!user && user == :false && user.has_liked?(child_node.get_value_object()))
        end
      end
    end

    def self.get_children(node)
      children = []
      links = Link.find(:all, 
                        :conditions => "(first_artist_id = #{node.value()} || second_artist_id = #{node.value()})",
                        :order => "grade DESC")
      links_limit = [links.length, Recommendation::MAX_CHILDREN_TO_EXPLORE].min() - 1
      
      for link in links[0..links_limit]
        link.first_artist_id == node.value() ? child_value = link.second_artist_id : child_value = link.first_artist_id
        if !node.exclude_values().include?(child_value)
          children << TreeNode.new(child_value, node, link, node.exclude_values().clone, Artist) # note no check of exclude values cause not treeing
        end
      end

      children
    end
    
    def self.already_in_nodes?(nodes, test_node)
      already_in_nodes = false
      for node in nodes
        if node.value() == test_node.value()
          already_in_nodes = true
          break
        end
      end
  
      already_in_nodes
    end
end