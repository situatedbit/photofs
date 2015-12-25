require 'node'

module PhotoFS
  class Dir < PhotoFS::Node
    def initialize(name, parent = nil)
      @nodes = {}

      super(name, parent)
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
end
