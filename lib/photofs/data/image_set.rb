require 'photofs/core/image_set'
require 'photofs/data/image'
require 'photofs/data/repository'

module PhotoFS
  module Data
    class ImageSet < PhotoFS::Core::ImageSet
      include Repository

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
        image_file = File.where(path: path).first

        return nil if image_file.nil?

        image_record = Image.find_by_image_file_id(image_file.id)

        return nil if image_record.nil?

        image = @record_object_map[image_record]

        if image
          image
        else
          @record_object_map[image_record] = image_record.to_simple
        end
      end

      def save!
        save_record_object_map(@record_object_map)
      end

      def size
        Image.count
      end

      protected

      def set
        @record_object_map = load_all_records(@record_object_map, Image)

        @record_object_map.values.to_set
      end

    end
  end
end
