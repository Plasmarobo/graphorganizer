class Node
  attr_accessor :parents
  attr_accessor :children
  attr_accessor :name
  attr_accessor :depth
  attr_accessor :x
  attr_accessor :domain
  attr_accessor :y

  def initialize(name, depth)
    @name = name
    @depth = depth
    @children = []
    @parents = []
    @x = 0
    @y = 0
    @domain = 0
  end

  def add_child(node)
    #node.shift_x (@x + @children.length)
    node.add_parent(self)
    if node.depth <= @depth
      node.depth = @depth + 1
    end
    node.x = @children.length
    @children << node
  end

  def add_parent(node)
    @parents << node
  end

end