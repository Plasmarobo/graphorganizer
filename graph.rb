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
    @icon = 32 
    @padding = 64
    @edge_pad = 256
    @icon_color = PNG::Color::Red 
    @path = 8
    @path_color = PNG::Color::Blue
    @width = 0
    @height = 0
    max_x = 0
    max_depth = 0

    traverse(@root) do |node|
      if node.x > max_x
        max_x = node.x
      end
      node.y = (node.depth * (@icon + @padding)) + @edge_pad
      if node.depth > max_depth
        max_depth = node.depth
      end
    end
    p max_x
    p max_depth
    @height = @edge_pad*2 + @padding + (max_depth * (@padding + @icon))
    @width  = @edge_pad*2 + @padding + (max_x     * (@padding + @icon))
    
    self.draw_nodes('raw.png')
  end


  def draw_nodes(image_name)
    
    canvas = PNG::Canvas.new @width,@height, PNG::Color::Black
    
    traverse(@root) do |node|
      puts "Width: #{@width}, Height: #{@height}"
      #Draw line, then icons
      x = (node.x     * (@icon + @padding)) + @edge_pad
      y = (node.y)
      puts "X: #{x}, Y: #{y}"
      cX = x + @icon/2
      cY = y + @icon/2

      node.parents.each do |pNode|
        if pNode != @root
          pX = (pNode.x     * (@icon + @padding)) + @edge_pad
          pY = (pNode.y)
          pCX = pX + @icon/2
          pCY = pY + @icon/2
          canvas.line(pCX, pCY, cX, cY, @path_color)
        end
      end      
      
      (y..(y+@icon-1)).each do |yPoint|
        (x..(x+@icon-1)).each do |xPoint|
          canvas.point(xPoint, yPoint, @icon_color)
        end
      end
      canvas.annotate(node.name, x, y)
    end

    image = PNG.new canvas
    image.save image_name

  end

  def domain_sort
    # Attempt to move nodes as close to their parent as possible. 
    @icon = 32 
    @padding = 16
    @edge_pad = 32
    @icon_color = PNG::Color::Red 
    @path = 8
    @path_color = PNG::Color::Blue
    @width = 0
    @height = 0
    max_x = 0
    max_depth = 0

    # Create a node pool
    master_node_pool = []
    depth_node_pool = [[]] # For level 0

    traverse(@root) do |node|
      node.domain = node.children.length
      master_node_pool << node
      if node.depth > max_depth
        max_depth = node.depth
      end
    end
    
    (1 .. max_depth).each do |level|
      depth_node_pool << []
      traverse(@root) do |node|
        if node.depth == level
          depth_node_pool[level] << node
        end
      end
    end

    node_pool = master_node_pool.uniq
    node_map = {}
    while !node_pool.empty?
      nodeA = node_pool.shift
      node_map[nodeA.name] = {}
      node_pool.each do |nodeB|
        if !node_map.has_key? nodeB
          node_map[nodeB.name] = {}
        end
        common_nodes = (nodeA.children.concat nodeB.children).group_by{ |e| e }.select { |k, v| v.size > 1 }.map(&:first)
        puts "Node Map #{nodeA.name} <-> #{nodeB.name} = #{common_nodes.length}"
        node_map[nodeA.name][nodeB.name] = common_nodes.length
        node_map[nodeB.name][nodeA.name] = common_nodes.length
      end
    end
    #node_pool = master_node_pool.uniq
    #Layout nodes, maximizing common node values
    #node_list = []
    #while !node_pool.empty?
    #  node = node_pool.shift
    #  if node_list.length < 3
    #    node_list << node
    #  else
    #    best_pointer = -1
    #    best_score = 0
    #    for pointer in (0..node_list.length-1)
    #      left = node_list[pointer]
    #      current = node_list[pointer+1]
    #      score = node_map[node][left] + node_map[node][current]
    #      if  score > best_score
    #        best_score = score
    #        best_pointer = pointer
    #      end
    #    end
    #    node_list.insert(best_pointer, node)
    #  end
    #end
    levels = [[]] #For level 0
    widest_level = 0
    (1 .. max_depth).each do |level|
      levels << []
      node_stream = depth_node_pool[level].uniq
      puts "Stream size #{node_stream.length}"
      if !node_stream.empty?
        while !node_stream.empty?
          node = node_stream.shift
          puts "Processing #{node.name}"
          if levels[level].length < 3
            levels[level] << node
          else
            best_position = -1
            best_score = 0
            for position in (-1 .. levels[level].length-1) do
              puts "Position #{position} of #{levels[level].length-1}"
              left_score = 0
              right_score = 0
              if position >= 0 and position < levels[level].length
                left = levels[level][position]
                puts "Selected Left as #{left.name} (#{position})"
                left_score = node_map[node.name][left.name]
                if left_score.nil?
                  left_score = 0
                end
              end
              
              if position+1 < levels[level].length and position+1 >= 0
                right = levels[level][position+1]
                puts "Selected Right as #{right.name} (#{position+1})"
                right_score = node_map[node.name][right.name]
                if right_score.nil?
                  right_score = 0
                end
              end
              puts "Scores: left #{left_score}, right #{right_score}"
              if (left_score + right_score) > best_score
                best_score = left_score + right_score
                best_position = position
              end
            end
            levels[level].insert(best_position, node)
          end
        end
        if levels[level].length > widest_level
          widest_level = levels[level].length
        end
      end
    end
  
    levels.select! {|level| !level.empty?}
    actual_depth = levels.length
    level_domain = (widest_level * (icon + padding)) + padding
    level_height = (actual_depth * (icon + padding)) + padding
    @width = level_domain + (edge_pad * 2)
    @height = level_height + (edge_pad * 2)
    # Levels should now be ordered
    # Inflate margins and groups
    y_stride = level_height / actual_depth
    y_offset = 0
    (1 .. max_depth).each do |level|
      domain_slice = level_domain / levels[level].length
      x_offset = domain_slice/2
      levels[level].each do |node|
        node.x = x_offset
        node.y = y_offset
        offset += domain_slice
      end
      y_offset += y_stride
    end
    
    self.draw_nodes('domain.png')

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