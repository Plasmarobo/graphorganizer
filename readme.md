GraphOrganizer
==============

GraphOrganizer intends to be an algorithm for laying out trees and graphs.
At present it only supports trees. 

Use:
Nodes may have N children and M parents.
Parents and children are defined for a node by using add_parent and add_child
Nodes must be constructed with a name and a depth. Depth may be overriden by parent.

The Graph class can accept an array of nodes via load_data. 
Calling render will produce a png image of the stored nodes.
Calling layout will attempt to produce a png with optimized layout.