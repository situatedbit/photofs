require 'node'

module PhotoFS
  class Dir < PhotoFS::Node
    def initialize(name, parent = nil)
      @nodes = nil

      super(name, parent)
    end

    def directory?
      true
    end

    def nodes
      @nodes.nil? ? [] : @nodes.values
    end

    def node_names
      @nodes.nil? ? [] : @nodes.keys
    end
  end
end
