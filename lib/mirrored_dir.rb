require_relative 'dir'
require_relative 'stat'
require_relative 'file'
require 'rfuse'

module PhotoFS
  class MirroredDir < PhotoFS::Dir
    attr_reader :source_path

    def initialize(name, source_path, options = {})
      @source_path = ::File.absolute_path(source_path)
      @options = default_options.merge options

      @tags = @options[:tags]

      raise ArgumentError.new('Source directory must be a directory') unless ::File.exist?(@source_path) || ::File.directory?(@source_path)

      super(name, options)
    end

    def mkdir(name)
      raise Errno::EPERM
    end

    def rmdir(name)
      raise Errno::EPERM
    end

    def stat
      stat_hash = PhotoFS::Stat.stat_hash(::File.stat(@source_path))

      RFuse::Stat.directory(PhotoFS::Stat::MODE_READ_ONLY, stat_hash)
    end

    protected

    def node_hash
      mirrored_nodes.merge tags_node
    end

    private

    def default_options
      {:tags => nil}
    end

    def entries
      ::Dir.entries(source_path) - ['.', '..']
    end

    def tags_node
      @tags ? {'tags' => TagDir.new('tags', @tags, {:parent => self} )} : {}
    end

    def mirrored_nodes
      Hash[entries.map { |e| [e, new_node(e)] }]
    end

    def new_node(entry)
      path = [source_path, entry].join(::File::SEPARATOR)

      if ::File.directory?(path)
        MirroredDir.new(entry, path, {:parent => self, :tags => @tags})
      else
        File.new(entry, path, {:parent => self})
      end
    end

  end
end
