require 'active_record'

require 'photofs/data/file'
require 'photofs/core/image'

module PhotoFS
  module Data
    class Image < ActiveRecord::Base
      belongs_to :jpeg_file, { :class_name => 'File', :autosave => true }

      validates :jpeg_file, presence: true
      validates :jpeg_file_id, uniqueness: true

      def self.from_image(image)
        Image.joins(:jpeg_file).where('files.path = ?', image.path).first
      end

      def self.new_from_image(image)
        image_record = Image.new
        image_record.build_jpeg_file(:path => image.path)

        image_record
      end

      def consistent_with?(image)
        jpeg_file && jpeg_file.path == image.path
      end

      def to_simple
        PhotoFS::Core::Image.new(jpeg_file.path)
      end

      def update_from(image)
        if jpeg_file.path != image.path
          build_jpeg_file(:path => image.path)
        end

        self
      end

    end
  end
end
