require 'photofs/core/image_set'
require 'photofs/data/image'

module PhotoFS
  module Data
    class ImageSet < PhotoFS::Core::ImageSet

      def initialize()
        @record_object_map = {} # maps Data::Image => Core::Image

        super
      end

      # Note that this will overwrite any cached versions of image, even
      # if the cached version is dirty. Returns simple image object.
      def add(image)
        image_record = Image.new_from_image(image)

        image_record.save!

        @record_object_map[image_record] = image
      end

      def empty?
        size == 0
      end

      def find_by_path(path)
        jpeg_file = File.where("path = ?", path).first

        return nil if jpeg_file.nil?

        image_record = Image.find_by_jpeg_file_id(jpeg_file.id)

        return nil if image_record.nil?

        image = @record_object_map[image_record]

        if image
          image
        else
          @record_object_map[image_record] = image_record.to_simple
        end
      end

      def save!
      end

      def size
        Image.count
      end

      protected

      def set
# nope: grab from database and cache        Set.new @record_object_map.values
      end


    end
  end
end
