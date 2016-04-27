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

      def &(image_sets)
        image_sets = [image_sets].flatten #normalize to array

        return PhotoFS::Core::ImageSet.new if image_sets.empty?

        first_set, remaining_sets = image_sets.first, image_sets[1..-1]

        # implicit intersection between database and first_set
        first_intersection = Image.from_images(first_set.to_a).map { |i| i.to_simple }

        intersection = remaining_sets.reduce(first_intersection.to_set) do |memo, image_set|
          memo & image_set.to_set
        end

        PhotoFS::Core::ImageSet.new(:set => intersection)
      end

      # Note that this will overwrite any cached versions of image, even
      # if the cached version is dirty. Returns simple image object.
      def add(image)
        image_record = Image.new_from_image(image)

        image_record.save!

        @record_object_map[image_record] = image
      end

      def clear_cache
        @record_object_map = {}
      end

      def empty?
        size == 0
      end

      def find_by_path(path)
        find_by_paths([path])[path]
      end

      def find_by_paths(paths)
        images_map = Image.find_by_image_file_paths(paths).map do |record|
          image = record_object_map_fetch(record)

          [image.path, image]
        end

        Hash[paths.zip []].merge Hash[images_map]
      end

      def import(paths)
        import_paths = paths - Image.exist_by_paths(paths)

        ActiveRecord::Base.transaction do
          return import_paths.map { |path| add PhotoFS::Core::Image.new(path) }
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

      private

      def record_object_map_fetch(record)
        @record_object_map[record] || @record_object_map[record] = record.to_simple
      end

    end
  end
end
