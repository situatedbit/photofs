require 'photofs/fuse/dir'

module PhotoFS
  module Fuse
    class RootDir < PhotoFS::Fuse::Dir

      def initialize()
        @nodes = {}

        super('')
      end

      def add(node)
        @nodes[node.name] = node

        node.parent = self

        node
      end

      def clear_cache
        @nodes.values.each { |node| node.clear_cache }
      end

      def mkdir(name)
        raise Errno::EPERM.new(name)
      end

      def rmdir(name)
        raise Errno::EPERM.new(name)
      end

      protected

      def node_hash
        @nodes
      end

      def relative_node_hash
        hash = { '.' => self }
      end

    end
  end
end
