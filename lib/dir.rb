require_relative 'node'

module PhotoFS
  class Dir < PhotoFS::Node

    def initialize(name, parent = nil)
      super(name, parent)
    end

    def directory?
      true
    end

    def mkdir(name)
      raise NotImplementedError
    end

    def rmdir(name)
      raise NotImplementedError
    end

    def nodes
      node_hash.values
    end

    # expect search to be an array of path compontents
    def search(path)
      return self if path.is_this?

      node = node_hash[path.top_name]

      if node
        node.directory? ? node.search(path.descend) : node
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
      raise NotImplementedError
    end

  end
end
