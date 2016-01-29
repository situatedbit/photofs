require_relative 'node'

module PhotoFS
  class Dir < PhotoFS::Node

    def initialize(name, options={})
      super(name, options)
    end

    def add(name, node)
      raise Errno::EPERM
    end

    def directory?
      true
    end

    def mkdir(name)
      raise NotImplementedError
    end

    def rename(child_name, to_parent, to_name)
      raise Errno::EPERM
    end

    def rmdir(name)
      raise NotImplementedError
    end

    def nodes
      relative_node_hash.merge node_hash
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

    def soft_move(node, name)
      raise Errno::EPERM
    end

    def stat
      RFuse::Stat.directory(Stat::MODE_READ_ONLY, {})
    end

    protected

    def node_hash
      raise NotImplementedError
    end

    def relative_node_hash
      { '.' => self, '..' => parent }
    end

  end
end
