require_relative 'dir'
require_relative 'stat'
require_relative 'file'
require_relative 'image_set'
require 'rfuse'

module PhotoFS
  class MirroredDir < PhotoFS::Dir
    attr_reader :source_path

    def initialize(name, source_path, options = {})
      @source_path = ::File.absolute_path(source_path)
      @options = default_options.merge options

      @tags = @options[:tags]
      @images_domain = @options[:images]

      raise ArgumentError.new('Source directory must be a directory') unless ::File.exist?(@source_path) || ::File.directory?(@source_path)

      super(name, options)
    end

    def mkdir(name)
      raise Errno::EPERM
    end

    def rename(from_name, to_parent, to_name)
      from_node = node_hash[from_name]

      raise Errno::ENOENT.new(from_name) unless from_node

      to_parent.soft_move(from_node, to_name)
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
      { :tags => nil,
        :images => PhotoFS::ImageSet.new }
    end

    def expand_path(entry)
      ::File.join(source_path, entry)
    end

    def images
      # images for each entry entries corresponding to an image in image domain
      entries.reduce([]) do |images, entry|
        image = @images_domain.find_by_path expand_path(entry)

        image ? images << image : images
      end
    end

    def entries
      ::Dir.entries(source_path) - ['.', '..']
    end

    def tags_node
      subdir_images_domain = @images_domain.filter do |i|
        images.include? i
      end

      @tags ? {'tags' => TagDir.new('tags', @tags, {:parent => self, :images => subdir_images_domain} )} : {}
    end

    def mirrored_nodes
      Hash[entries.map { |e| [e, new_node(e)] }]
    end

    def new_node(entry)
      path = expand_path(entry)

      if ::File.directory?(path)
        MirroredDir.new(entry, path, {:parent => self, :tags => @tags, :images => @images_domain})
      else
        File.new(entry, path, {:parent => self, :payload => @images_domain.find_by_path(path)})
      end
    end

  end
end
