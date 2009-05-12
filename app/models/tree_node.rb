class TreeNode
  attr_accessor :children, :value, :parent, :link_to_parent, :exclude_values, :clazz
    
  def initialize(value, parent, link_to_parent, exclude_values, clazz)
    @value = value
    @parent = parent
    @link_to_parent = link_to_parent
    @children = []
    @exclude_values = exclude_values
    @exclude_values << value
    @clazz = clazz
  end

  # returns product of grades of node and ancestors
  def get_grade(user)
    chain_grade = 1
    for link in get_chain_as_links()
      chain_grade *= link.get_grade(user)
    end

    chain_grade
  end
  
  def get_chain()
    chain = [self.value]
    current_node = self
    while parent = current_node.parent()
      chain << parent.value
      current_node = parent
    end
    
    chain.reverse()
  end
  
  def get_chain_as_links()
    chain_as_links = []
    chain_as_links << @link_to_parent if @link_to_parent
    
    current_node = self
    while parent = current_node.parent()
      chain_as_links << parent.link_to_parent if parent.link_to_parent
      current_node = parent
    end
    
    chain_as_links.reverse()
  end
  
  def get_value_object()
    clazz().find(value()) if clazz()
  end
end