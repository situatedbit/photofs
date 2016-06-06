require 'photofs/core/tag'
require 'photofs/core/tag_set'
require 'photofs/core/image_set'
require 'photofs/fuse/dir'
require 'photofs/fuse/stats_file'

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

      def clear_cache
        @node_hash = nil
      end

      def mkdir(tag_name)
        raise Errno::EPERM.new(tag_name) unless is_tags_root?

        tag = PhotoFS::Core::Tag.new tag_name

        raise Errno::EEXIST.new(tag_name) if dir_tags.include?(tag)

        @tags.add?(tag)
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
                      :size => 1024 } # arbitrary

        mode = Stat.add Stat::MODE_READ_ONLY, Stat::PERM_USER_WRITE

        RFuse::Stat.directory(mode, stat_hash)
      end

      def symlink(image, name)
        raise Errno::EPERM if is_tags_root? || !@images_domain.include?(image)

        tag_image(image)
      end

      protected

      def node_hash
        @node_hash ||= files.merge dirs
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

      def dir_tags
        if is_tags_root?
          @tags.all
        else
          @tags.find_by_image(images) - query_tags
        end
      end

      def files
        images_sorted = images.sort { |a, b| a.path <=> b.path }

        file_name_map = {}

        images_sorted.each do |image|
          basename = ::File.basename image.path

          name = file_name_map[basename] ? unique_image_name(image) : basename

          file_name_map[name] = File.new(name, PhotoFS::FS.file_system.absolute_path(image.path), {:parent => self, :payload => image})
        end

        is_tags_root? ? file_name_map.merge( {'stats' => stats_file} ) : file_name_map
      end

      def images
        # put images domain at the front of the array for #intersection call to take advantage of 
        # Data::ImageSet's implementation
        is_tags_root? ? [] : PhotoFS::Core::TagSet.intersection([@images_domain] + query_tags).to_a
      end

      def is_tags_root?
        @query_tag_names.empty?
      end

      def stats_file
        StatsFile.new 'stats', :tags => @tags.limit_to_images(@images_domain)
      end

      def query_tags
        @tags.find_by_name(@query_tag_names)
      end

      def unique_image_name(image)
        extension = ::File.extname image.path
        basename = ::File.basename image.path, extension
        escaped_path = ::File.dirname(image.path).gsub(::File::SEPARATOR, '-')

        "#{basename}#{escaped_path}#{extension}"
      end

    end
  end
end
