require './node.rb'
require 'png'
require 'png/font'

class Graph
	@root = nil

  def initialize
    @root = Node.new("root", 0)
    @debug_level = 0
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
      #Draw line, then icons
      node.x *= (@padding + @icon)
      node.y *= (@padding + @icon)
      node.draw_lines(canvas, @icon, @edge_pad, @path_color)
      
      node.draw(canvas, @icon, @edge_pad, @icon_color)
    end

    image = PNG.new canvas
    image.save image_name

  end

  def domain_sort
    # Attempt to move nodes as close to their parent as possible. 
    @icon = 64 
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
        node_map[nodeA.name][nodeB.name] = common_nodes.length
        node_map[nodeB.name][nodeA.name] = common_nodes.length
      end
    end

    levels = [[]] #For level 0
    widest_level = 0
    (1 .. max_depth).each do |level|
      levels << []
      node_stream = depth_node_pool[level].uniq
      if !node_stream.empty?
        while !node_stream.empty?
          node = node_stream.shift
          if levels[level].length < 3
            levels[level] << node
          else
            best_position = -1
            best_score = 0
            for position in (-1 .. levels[level].length-1) do
              left_score = 0
              right_score = 0
              if position >= 0 and position < levels[level].length
                left = levels[level][position]
                left_score = node_map[node.name][left.name]
                if left_score.nil?
                  left_score = 0
                end
              end
              
              if position+1 < levels[level].length and position+1 >= 0
                right = levels[level][position+1]
                right_score = node_map[node.name][right.name]
                if right_score.nil?
                  right_score = 0
                end
              end
              if (left_score + right_score) > best_score
                best_score = left_score + right_score
                best_position = position
              end
            end
            levels[level].insert(best_position, node)
          end
          dump_level(levels)
        end
        if levels[level].length > widest_level
          widest_level = levels[level].length
        end
      end
    end
  
    levels.select! {|level| !level.empty?}
    actual_depth = levels.length
    level_domain = (widest_level * (@icon + @padding)) + @padding
    level_height = (actual_depth * (@icon + @padding)) + @padding
    @width = level_domain + (@edge_pad * 2)
    @height = level_height + (@edge_pad * 2)
    canvas = PNG::Canvas.new @width,@height, PNG::Color::Black
    # Levels should now be ordered
    # Inflate margins and groups
    y_stride = level_height / actual_depth
    y_offset = 0
    x_offset = 0
    newroot = Node.new("root", 0)
    (1 .. levels.length-1).each do |level|
      puts levels[level]
      domain_slice = level_domain / levels[level].length
      x_offset = domain_slice/2
      levels[level].each do |node|
        node.x = x_offset
        node.y = y_offset
        x_offset += domain_slice
      end
      y_offset += y_stride
    end
    (levels.length-1).downto(1).each do |level|
      puts "Drawing level #{level}"
      nodes = levels[level]
      nodes.each do |node|
        node.draw_lines(canvas, @icon, @edge_pad, @path_color)
      end
      nodes.each do |node|
        node.draw(canvas, @icon, @edge_pad, @path_color)
      end
    end
    image = PNG.new canvas
    image.save 'domain.png'

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

    def dump_level(levels)

      w = 0
      h = (levels.length * (@icon + @padding)) + (@edge_pad * 2) + @padding
      levels.each do |level|
        if level.length > w
          w = level.length
        end
      end
      w *= (@icon + @padding)
      w += @padding + (@edge_pad * 2)
      canvas = PNG::Canvas.new w,h, PNG::Color::Black
      y = 0
      levels.each do |level|
        x = 0
        level.each do |node|
          node.x = x * (@icon + @padding) + @edge_pad
          node.y = y * (@icon + @padding) + @edge_pad
          node.draw_lines(canvas, @icon, @edge_pad, @path_color)
          node.draw(canvas, @icon, @edge_pad, @icon_color)
          x += 1
        end
        y += 1
      end
      image = PNG.new canvas
      image.save "sequence%06d.png" % @debug_level
      @debug_level += 1
    end

end
