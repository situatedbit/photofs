require 'active_record'

require 'photofs/data/file'
require 'photofs/core/image'

module PhotoFS
  module Data
    class Image < ActiveRecord::Base
      belongs_to :jpeg_file, { :class_name => 'File', :autosave => true }

      validates :jpeg_file, presence: true
      validates :jpeg_file_id, uniqueness: true

      def self.new_from_image(image)
        image_record = Image.new
        image_record.build_jpeg_file(:path => image.path)

        image_record
      end

      def to_simple
        PhotoFS::Core::Image.new(jpeg_file.path)
      end

    end
  end
end
