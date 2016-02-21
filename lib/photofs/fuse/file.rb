require_relative 'fuse'
require_relative 'node'
require_relative 'stat'
require 'rfuse'

module PhotoFS
  module Fuse
    class File < PhotoFS::Fuse::Node
      attr_reader :target_path

      def initialize(name, target_path, options = {})
        @target_path = Fuse.fs.absolute_path target_path

        raise ArgumentError.new('Target path must be a file') unless Fuse.fs.exist?(@target_path)

        super(name, options)
      end

      def stat
        stat_hash = Stat.stat_hash(Fuse.fs.stat(@target_path))

        stat_hash[:mode] = RFuse::Stat::S_IFLNK | Stat::MODE_READ_ONLY
        stat_hash[:nlink] = 1
        stat_hash[:size] = @target_path.length

        RFuse::Stat.new(RFuse::Stat::S_IFLNK, Stat::MODE_READ_ONLY, stat_hash)
      end
    end
  end
end
