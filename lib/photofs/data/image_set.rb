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

      def find_by_path_parent(path)
        Image.find_by_path_parent(path).map { |record| record_object_map_fetch(record) }
      end

      def include?(image)
        !!Image.from_image(image)
      end

      def import!(paths)
        import_paths = paths.each_slice(50).reduce([]) do |paths_to_import, paths_to_check|
          paths_to_import.append *(paths_to_check - Image.exist_by_paths(paths_to_check))
        end

        ActiveRecord::Base.transaction do
          return import_paths.map { |path| add PhotoFS::Core::Image.new(path) }
        end
      end

      def remove(image)
        record = PhotoFS::Data::Image.from_image image

        return nil unless record

        @record_object_map.delete record

        record.destroy

        image
      end

      def save!
        save_record_object_map(@record_object_map)
      end

      def sidecars(images)
        # optimization: use core::ImageSet implementation, but narrow the
        # domain from all images in the database down to candidates based
        # on paths
        domain = Image.find_by_sidecar_candidates(images).map do |record|
          record_object_map_fetch(record)
        end

        PhotoFS::Core::ImageSet.new(set: domain.to_set).sidecars(images)
      end

      def size
        Image.count
      end

      protected

      def set
        @record_object_map = load_all_records(@record_object_map, Image)

        @record_object_map.values.to_set
      end

      def intersect(image_set)
        Image.from_images(image_set.to_a).reduce(Set.new) { |set, i| set << i.to_simple }
      end

      private

      def record_object_map_fetch(record)
        @record_object_map[record] || @record_object_map[record] = record.to_simple
      end

    end
  end
end
