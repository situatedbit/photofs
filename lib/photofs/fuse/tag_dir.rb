require_relative 'dir'
require 'photofs/core/tag'
require 'photofs/core/tag_set'
require 'photofs/core/image_set'

module PhotoFS
  module Fuse
    class TagDir < PhotoFS::Fuse::Dir
      def initialize(name, tags, options = {})
        @tags = tags
        @options = default_options.merge options

        @query_tag_names = @options[:query_tag_names]
        @images_domain = @options[:images]

        super(name, options)
      end

      def add(name, node)
        raise Errno::EPERM if is_tags_root?

        image = node.payload

        raise Errno::EEXIST.new(node.path) if images.include? image

        raise Errno::EPERM unless @images_domain.include? image

        query_tags.each do |tag|
          tag.add image
        end
      end

      def mkdir(tag_name)
        raise Errno::EPERM.new(tag_name) unless is_tags_root?

        tag = PhotoFS::Core::Tag.new tag_name

        raise Errno::EEXIST.new(tag_name) if dir_tags.include?(tag)

        @tags.add?(tag)
      end

      def rename(child_name, to_parent, to_name)
        raise NotImplementedError
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
        tag = @tags.find_by_name tag_name

        raise Errno::ENOENT.new(tag_name) unless tag && dir_tags.include?(tag)
        raise Errno::EPERM unless is_tags_root?
        raise Errno::EPERM unless tag.images.empty?

        @tags.delete tag
      end

      def soft_move(node, name)
        raise Errno::EPERM if is_tags_root?
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
                      :size => size }

        mode = Stat.add Stat::MODE_READ_ONLY, Stat::PERM_USER_WRITE

        RFuse::Stat.directory(mode, stat_hash)
      end

      def symlink(image, name)
        raise Errno::EPERM if is_tags_root? || !@images_domain.include?(image)

        tag_image(image)
      end

      protected

      def node_hash
        Hash[ (files + dirs).map { |n| [n.name, n] } ]
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
        dir_tags.map do |tag|
          TagDir.new(tag.name, @tags, {:query_tag_names => @query_tag_names + [tag.name], :parent => self, :images => @images_domain})
        end
      end

      def dir_tags
        if is_tags_root?
          @tags.all
        else
          @tags.find_by_image(images.to_a) - query_tags
        end
      end

      def files
        images.all.map { |image| File.new(image.name, image.path, {:parent => self, :payload => image}) }
      end

      def images
        PhotoFS::Core::TagSet.intersection(query_tags)
      end

      def is_tags_root?
        @query_tag_names.empty?
      end

      def size
        node_hash.values.reduce(0) { |size, node| size + node.name.length }
      end

      def query_tags
        @tags.find_by_name(@query_tag_names)
      end

    end
  end
end
