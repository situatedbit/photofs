require 'photofs/core/image_set'
require 'photofs/core/tag'
require 'photofs/core/tag_set'
require 'photofs/fuse/dir'
require 'photofs/fuse/sidecars_dir'
require 'photofs/fuse/stats_file'

module PhotoFS
  module Fuse
    class TagDir < PhotoFS::Fuse::Dir
      attr_reader :images_domain, :tags

      def initialize(name, tags, options = {})
        @tags = tags
        @options = default_options.merge options

        @query_tag_names = @options[:query_tag_names]
        @images_domain = @options[:images]

        super(name, options)
      end

      def add(name, node)
        image = node.payload

        raise Errno::EEXIST.new(node.path) if images.include? image

        raise Errno::EPERM unless @images_domain.include? image

        query_tags.each do |tag|
          tag.add image
        end
      end

      def clear_cache
        @node_hash = nil
      end

      def mkdir(tag_name)
        raise Errno::EPERM.new(tag_name)
      end

      def remove(child_name)
        child = node_hash[child_name]

        raise Errno::ENOENT.new(child_name) if child.nil?
        raise Errno::EPERM if child.directory?

        image = child.payload

        query_tags.each do |tag|
          tag.remove image
        end
      end

      def rmdir(tag_name)
        raise Errno::EPERM
      end

      def soft_move(node, name)
        raise Errno::EPERM if node.directory?

        image = node.payload

        raise Errno::EPERM unless @images_domain.include? image
        raise Errno::EPERM if images.include? image

        tag_image(image)
      end

      def stat
        stat_hash = { :atime => Time.now,
                      :ctime => Time.now,
                      :mtime => Time.now,
                      :size => 1024 } # arbitrary

        mode = Stat.add Stat::MODE_READ_ONLY, Stat::PERM_USER_WRITE

        RFuse::Stat.directory(mode, stat_hash)
      end

      def symlink(image, name)
        raise Errno::EPERM unless @images_domain.include?(image)

        tag_image(image)
      end

      protected

      def additional_files
        # can be implemented by subclasses
        {}
      end

      def dir_tags
        # can be implemented by subclasses. Tags for which a subdirectory should exist in this dir.
        @tags.find_by_images(images) - query_tags
      end

      def images
        # can be implemented by subclasses. Images to be represented as files in this dir.

        # put images domain at the front of the array for #intersection call to take advantage of
        # Data::ImageSet's implementation
        PhotoFS::Core::TagSet.intersection([@images_domain] + query_tags)
      end

      def node_hash
        files_node = files

        nodes = files_node.empty? ? [files_node, dirs] : [files_node, dirs, sidecars_dir]

        @node_hash ||= nodes.reduce({}) { |hash, nodes| hash.merge nodes }
      end

      def sidecars_dir
        name = 'sidecars'

        { name => PhotoFS::Fuse::SidecarsDir.new(name, images_domain: images_domain, images: images, parent: self) }
      end

      private

      def tag_image(image)
        query_tags.each do |tag|
          tag.add image
        end
      end

      def default_options
        { :query_tag_names => [],
          :images => PhotoFS::Core::ImageSet.new }
      end

      def dirs
        dir_name_map = {}

        dir_tags.each do |tag|
          tag_dir = TagDir.new(tag.name, @tags, {:query_tag_names => @query_tag_names + [tag.name], :parent => self, :images => @images_domain})

          dir_name_map[tag.name] = tag_dir
        end

        dir_name_map
      end

      def files
        images_sorted = images.all.sort { |a, b| a.path <=> b.path }

        file_name_map = {}

        images_sorted.each do |image|
          basename = ::File.basename image.path

          name = file_name_map[basename] ? unique_image_name(image) : basename

          file_name_map[name] = File.new(name, PhotoFS::FS.expand_path(image.path), {:parent => self, :payload => image})
        end

        file_name_map.merge additional_files
      end

      def query_tags
        @tags.find_by_name(@query_tag_names)
      end

      def unique_image_name(image)
        extension = ::File.extname image.path
        basename = ::File.basename image.path, extension
        escaped_path = "-" + ::File.dirname(image.path).gsub(::File::SEPARATOR, '-')

        "#{basename}#{escaped_path}#{extension}"
      end

    end
  end
end
