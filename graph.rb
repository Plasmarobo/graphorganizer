require './node.rb'
require 'png'
require 'png/font'

class Graph
	@root = nil

  def initialize
    @root = Node.new("root", 0)
  end

  def load_data(nodes)
    nodes.each do |node|
      if node.parents.empty?
        @root.add_child(node)
      end
    end
  end

	def test_data
    srand(5)
		#Add some nodes connected to root nodes
    @root = Node.new("root", 0)
    last_node = @root
    consecutive = 0
    (1..50).each do |index|
      depth = rand(11)
      node = Node.new("#{index}", depth)
      if rand(20) > 5 + consecutive
        last_node.add_child(node)
        last_node = node
        consecutive += 1
      else
        @root.add_child(node)
        last_node = @root
        consecutive = 0
      end
      
    end
	end

  def render
    icon = 32 
    padding = 64
    edge_pad = 256
    icon_color = PNG::Color::Red 
    path = 8
    path_color = PNG::Color::Blue
    width = 0
    height = 0
    max_x = 0
    max_depth = 0

    traverse(@root) do |node|
      if node.x > max_x
        max_x = node.x
      end
      if node.depth > max_depth
        max_depth = node.depth
      end
    end
    p max_x
    p max_depth
    height = edge_pad*2 + padding + (max_depth * (padding + icon))
    width  = edge_pad*2 + padding + (max_x     * (padding + icon))
    canvas = PNG::Canvas.new width,height, PNG::Color::Black

    traverse(@root) do |node|
      #Draw line, then icons
      x = (node.x     * (icon + padding)) + edge_pad
      y = (node.depth * (icon + padding)) + edge_pad
      cX = x + icon/2
      cY = y + icon/2

      node.parents.each do |pNode|
        if pNode != @root
          pX = (pNode.x     * (icon + padding)) + edge_pad
          pY = (pNode.depth * (icon + padding)) + edge_pad
          pCX = pX + icon/2
          pCY = pY + icon/2
          canvas.line(pCX, pCY, cX, cY, path_color)
        end
      end      

      (y..(y+icon-1)).each do |yPoint|
        (x..(x+icon-1)).each do |xPoint|
          canvas.point(xPoint, yPoint, icon_color)
        end
      end
      canvas.annotate(node.name, x, y)
    end

    image = PNG.new canvas
    image.save 'raw.png'

  end

  def domain_sort
    # Attempt to move nodes as close to their parent as possible. 
    @icon = 32 
    @padding = 16
    edge_pad = 256
    icon_color = PNG::Color::Red 
    path = 8
    path_color = PNG::Color::Blue
    width = 0
    height = 0
    max_x = 0
    max_depth = 0

    # Create a node pool
    master_node_pool = []

    traverse(@root) do |node|
      node.domain = node.children.length
      master_node_pool << node
    end

    node_pool = master_node_pool.uniq
    node_map = {}
    while !node_pool.empty?
      nodeA = node_pool.shift
      node_map[nodeA] = {}
      node_pool.each do |nodeB|
        if !node_map.has_key? nodeB
          node_map[nodeB] = {}
        end
        common_nodes = (nodeA.children.concat nodeB.children).group_by{ |e| e }.select { |k, v| v.size > 1 }.map(&:first)
        node_map[nodeA][nodeB] = common_nodes.length
        node_map[nodeB][nodeA] = common_nodes.length
      end
    end
    node_pool = master_node_pool.uniq
    #Layout nodes, maximizing common node values
    node_list = []
    while !node_pool.empty?
      node = node_pool.shift
      if node_list.length < 3
        node_list << node
      else
        best_pointer = -1
        best_score = 0
        for pointer in (0..node_list.length-1)
          left = node_list[pointer]
          current = node_list[pointer+1]
          score = node_map[node][left] + node_map[node][current]
          if  score > best_score
            best_score = score
            best_pointer = pointer
          end
        end
        node_list.insert(best_pointer, node)
      end
    end

    # Inflate tree

    image = PNG.new canvas
    image.save 'layout.png'

  end

  private

    def traverse(node, &proc)
      node.children.each do |child|
        traverse(child, &proc) 
      end
      if node != @root
        yield node
      end
    end

    def pl(msg,level)
      str = ""
      level.times do 
        str += "  "
      end
      #p str + msg
    end

    


end