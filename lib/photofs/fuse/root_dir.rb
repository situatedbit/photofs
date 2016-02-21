require_relative 'dir'

module PhotoFS
  module Fuse
    class RootDir < PhotoFS::Fuse::Dir

      def initialize()
        @nodes = {}

        super('')
      end

      def add(dir)
        raise ArgumentError.new("Only directories can be added to a root directory") unless dir.directory?

        @nodes[dir.name] = dir
        dir.parent = self

        dir
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
