require_relative 'dir'
require_relative 'stat'
require_relative 'file'
require 'photofs/core/image_set'
require 'photofs/fs'
require 'rfuse'

module PhotoFS
  module Fuse
    class MirroredDir < PhotoFS::Fuse::Dir
      attr_reader :source_path

      def initialize(name, source_path, options = {})
        @source_path = fs.absolute_path(source_path)
        @options = default_options.merge options

        @tags = @options[:tags]
        @images_domain = @options[:images]

        raise ArgumentError.new('Source directory must be a directory') unless fs.exist?(@source_path) || fs.directory?(@source_path)

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
        stat_hash = PhotoFS::Fuse::Stat.stat_hash(fs.stat(@source_path))

        RFuse::Stat.directory(PhotoFS::Fuse::Stat::MODE_READ_ONLY, stat_hash)
      end

      protected

      def node_hash
        mirrored_nodes.merge tags_node
      end

      private

      def default_options
        { :tags => nil,
          :images => PhotoFS::Core::ImageSet.new }
      end

      def expand_path(entry)
        fs.join(source_path, entry)
      end

      def images
        # images for each entry entries corresponding to an image in image domain
        entries.reduce([]) do |images, entry|
          image = @images_domain.find_by_path expand_path(entry)

          image ? images << image : images
        end
      end

      def entries
        fs.entries(source_path) - ['.', '..']
      end

      def tags_node
        tag_dir_image_set = PhotoFS::Core::ImageSet.new({set: Set.new(images)})

        return {} if @tags.nil? || tag_dir_image_set.empty?

        {'tags' => TagDir.new('tags', @tags, {:parent => self, :images => tag_dir_image_set} )}
      end

      def mirrored_nodes
        Hash[entries.map { |e| [e, new_node(e)] }]
      end

      def new_node(entry)
        path = expand_path(entry)

        if fs.directory?(path)
          MirroredDir.new(entry, path, {:parent => self, :tags => @tags, :images => @images_domain})
        else
          File.new(entry, path, {:parent => self, :payload => @images_domain.find_by_path(path)})
        end
      end

      private
      def fs
        PhotoFS::FS.file_system
      end

    end
  end
end