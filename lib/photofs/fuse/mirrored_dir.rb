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

      def clear_cache
        @node_hash = nil
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
        @node_hash ||= mirrored_nodes.merge tags_node
      end

      private

      def default_options
        { :tags => nil,
          :images => PhotoFS::Core::ImageSet.new }
      end

      def dir_entries
        entries.select { |entry| fs.directory? expand_path(entry) }
      end

      def dir_node(entry, path)
        MirroredDir.new(entry, path, {:parent => self, :tags => @tags, :images => @images_domain})
      end

      def entries
        fs.entries(source_path) - ['.', '..']
      end

      def expand_path(entry)
        fs.join(source_path, entry)
      end

      def file_entries
        entries - dir_entries
      end

      def file_node(entry, path, payload)
        File.new(entry, fs.absolute_path(path), {:parent => self, :payload => payload})
      end

      def images
        # images for each entry entries corresponding to an image in image domain
        paths = entries.map { |e| expand_path e }

        @images_domain.find_by_paths(paths).values.select { |image| image }
      end

      def mirrored_dir_nodes(dir_entries)
        dir_nodes = []

        dir_entries.each_pair do |path, entry|
          dir_nodes << [entry, dir_node(entry, path)]
        end

        dir_nodes
      end

      def mirrored_file_nodes(file_entries)
        file_nodes = []

        @images_domain.find_by_paths(file_entries.keys).each_pair do |path, image|
          entry = file_entries[path]

          file_nodes << [entry, file_node(entry, path, image)]
        end

        file_nodes
      end

      def mirrored_nodes
        files = Hash[file_entries.map { |e| [expand_path(e), e] }]
        dirs = Hash[dir_entries.map { |e| [expand_path(e), e] }]

        Hash[mirrored_file_nodes(files) + mirrored_dir_nodes(dirs)]
      end

      def tags_node
        tag_dir_image_set = PhotoFS::Core::ImageSet.new({set: Set.new(images)})

        return {} if @tags.nil? || tag_dir_image_set.empty?

        {'tags' => TagDirRoot.new('tags', @tags, {:parent => self, :images => tag_dir_image_set} )}
      end

      private
      def fs
        PhotoFS::FS.file_system
      end

    end
  end
end
