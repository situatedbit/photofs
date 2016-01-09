require_relative 'node'

module PhotoFS
  class Dir < PhotoFS::Node

    def initialize(name, parent = nil)
      @nodes = nil

      super(name, parent)
    end

    def add(node)
      @nodes ||= {}

      @nodes[node.name] = node
      node.parent = self

      node
    end

    def directory?
      true
    end

    def mkdir(name)
      raise Errno::EEXIST.new(name) if node_hash.has_key?(name)

      add Dir.new(name)
    end

    def nodes
      node_hash.values
    end

    # expect search to be an array of path compontents
    def search(path)
      return self if path.empty?

      node = node_hash[path.first]

      if node
        node.directory? ? node.search(path.slice(1, path.size)) : node
      else
        nil
      end
    end

    def stat
      RFuse::Stat.directory(Stat::MODE_READ_ONLY, {})
    end

    protected

    # implement this in subclass to support memoization
    def node_hash
      @nodes.nil? ? {} : @nodes
    end

  end
end
