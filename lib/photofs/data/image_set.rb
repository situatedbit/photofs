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
        @record_object_map.each_pair do |record, simple_object|
          if !record.consistent_with?(simple_object)
            record.update_from(simple_object)
            record.save!
          end
        end

        @record_object_map.rehash
      end

      def size
        Image.count
      end

      protected

      def set
        cached_ids = @record_object_map.keys.map { |record| record.id }

        image_records = Image.where.not(id: cached_ids)

        image_records.all.each { |record| @record_object_map[record] = record.to_simple }

        @record_object_map.values.to_set
      end

    end
  end
end
