require 'dir'
require 'stat'
require 'rfuse'

module PhotoFS
  class MirroredDir < PhotoFS::Dir
    attr_reader :source_path

    def initialize(name, source_path, parent = nil)
      @source_path = ::File.absolute_path(source_path)

      raise ArgumentError, 'Source directory must be a directory' unless ::File.exist?(@source_path) || ::File.directory?(@source_path)

      super(name, parent)
    end

    def stat
      stat_hash = PhotoFS::Stat.stat_hash(::File.stat(@source_path))

      RFuse::Stat.directory(PhotoFS::Stat::MODE_READ_ONLY, stat_hash)
    end

    def nodes
      Hash[entries.map { |e| [e, new_node(e)] }].values
    end

    private

    def entries
      ::Dir.entries(source_path) - ['.', '..']
    end

    def new_node(entry)
      path = [source_path, entry].join(::File::SEPARATOR)

      ::File.directory?(path) ? MirroredDir.new(entry, path, self) : File.new(entry, path, self)
    end
  end
end
