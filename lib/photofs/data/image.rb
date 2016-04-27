require 'active_record'

require 'photofs/data/file'
require 'photofs/core/image'

module PhotoFS
  module Data
    class Image < ActiveRecord::Base
      belongs_to :image_file, { :class_name => 'File', :autosave => true }

      validates :image_file, presence: true
      validates :image_file_id, uniqueness: true

      def self.find_by_image_file_paths(paths)
        Image.joins(:image_file).where('files.path in (?)', paths)
      end

      def self.from_image(image)
        Image.joins(:image_file).where('files.path = ?', image.path).first
      end

      def self.from_images(images)
        find_by_image_file_paths(images.map { |i| i.path })
      end

      def self.new_from_image(image)
        image_record = Image.new
        image_record.build_image_file(:path => image.path)

        image_record
      end

      def self.exist_by_paths(paths)
        find_by_image_file_paths(paths).all.map { |image| image.path }
      end

      def consistent_with?(image)
        image_file && path == image.path
      end

      def path
        image_file.path
      end

      def to_simple
        PhotoFS::Core::Image.new(image_file.path)
      end

      def update_from(image)
        if path != image.path
          build_image_file(:path => image.path)
        end

        self
      end

    end
  end
end
