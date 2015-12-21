require 'node'

class PhotoDir < Node
  def initialize(name, parent = nil)
    @nodes = {}

    super(name, parent)
  end

  def add_node(node)
    @nodes[node.name] = node

    node
  end

  def directory?
    true
  end

#  def find(path); end

  def nodes
    @nodes.values
  end

  def node_names
    @nodes.keys
  end

#  def stat; end
end
