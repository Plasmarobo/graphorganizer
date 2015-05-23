require 'csv'

edges = []
output = File.open("result.rb", "w")
output << "nodes = []\n"
CSV.foreach("data.csv", headers: true) do |row|
  p row
  name = ""
  row.each do |header, column|
    if header == 'Name'
      name = column.downcase.gsub(/[^a-z]/, '')
      output << "nodes << (node_"
      output << name
      output << " = Node.new("
      output << "'#{column}'"   
    elsif header == 'Prerequisites'
      depth = 0
      if column != nil
        CSV.parse(column) do |row|
          row.each do |reference|
            if (level = /Level\s*(\d*)/.match(reference)) != nil
              depth = level[1].to_i
            else
              if reference != nil and reference != "nil"
                edges << "node_#{reference.downcase.gsub(/[^0-9A-Za-z]/, '')}.add_child(node_#{name})\n"
              end
            end
          end
        end
      end
      output << ",#{depth}))\n"
    end
  end
 end
 edges.each do |edge|
  output << edge
end
 
output.close