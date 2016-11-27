require 'photofs/core/image_set'
require 'photofs/fs'
require 'photofs/fuse/dir'
require 'photofs/fuse/file'

module PhotoFS
  module Fuse
    class SidecarsDir < PhotoFS::Fuse::Dir
      attr_reader :images
      attr_reader :images_domain

      def initialize(name, options = {})
        @options = default_options.merge options

        @images_domain = options[:images_domain]
        @images = options[:images]

        super(name, options)
      end

      protected

      def node_hash
        hash = {}

        sidecar_images.each do |image|
          name = ::File.basename image.path

          hash[name] = File.new(name, PhotoFS::FS.expand_path(image.path), {:parent => self, :payload => image})
        end

        hash
      end

      private

      def default_options
        { images_domain: PhotoFS::Core::ImageSet.new,
          images: PhotoFS::Core::ImageSet.new }
      end

      def sidecar_images
        images_domain.sidecars(images)
      end
    end
  end
end
