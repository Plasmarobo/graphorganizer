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

  def draw(canvas, icon_size, border_size, icon_color)
    x = (self.x + border_size)
    y = (self.y + border_size)

    (y..(y+icon_size-1)).each do |yPoint|
      (x..(x+icon_size-1)).each do |xPoint|
        canvas.point(xPoint, yPoint, icon_color)
      end
    end
    canvas.annotate(self.name, x, y)
  end

  def draw_lines(canvas, icon_size, border_size, line_color)
    x = (self.x + border_size)
    y = (self.y + border_size)
    cX = x + icon_size/2
    cY = y + icon_size/2

    self.parents.each do |pNode|
      if pNode != @root
        pX = (pNode.x + border_size)
        pY = (pNode.y + border_size)
        pCX = pX + icon_size/2
        pCY = pY + icon_size/2
        canvas.line(pCX, pCY, cX, cY, line_color)
      end
    end      
  end

end