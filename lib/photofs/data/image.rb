require 'active_record'

require 'photofs/core/image'

module PhotoFS
  module Data
    class Image < ActiveRecord::Base
      has_many :tag_bindings, dependent: :delete_all
      has_many :tags, through: :tag_bindings

      validates :path, presence: true
      validates_uniqueness_of :path, case_sensitive: true

      def self.find_by_paths_start(paths)
        paths = [paths].flatten.map { |p| "#{p}%"} # normalize to array, add LIKE wildcard

        where_clause = paths.map { "path LIKE ?" }.join(' or ')

        Image.where(where_clause, *paths)
      end

      def self.find_by_image_file_paths(paths)
        Image.where('path in (?)', paths)
      end

      def self.find_by_path_parent(path)
        # if path isn't empty, must end with / to prevent selecting 2.jpg from 'some/path/1.jpg',
        #   'some/path-to-file/2.jpg' with path='some/path'
        # Note: by design, this will return images in subdirectories under path as well.
        path_filter = path.end_with?(::File::SEPARATOR) ? path : "#{path}#{::File::SEPARATOR}"

        case path
        when '' then Image.all
        else Image.where('instr(path, ?) = 1', path_filter)
        end
      end

      # Returns images that _might_ be sidecars. There seems to be no to_simple
      # query that can return a more narrow set of sidecars, given our rules
      # for sidecars. Query greedily, then trim the set locally.
      def self.find_by_sidecar_candidates(images)
        # This is brittle. It assumes sidecars will be determined by the
        # beginning of the name.
        reference_paths = images.map { |i| i.reference_path }

        find_by_paths_start(reference_paths)
      end

      def self.from_image(image)
        Image.where(path: image.path).first
      end

      def self.from_images(images)
        find_by_image_file_paths(images.map { |i| i.path })
      end

      def self.new_from_image(image)
        Image.new(path: image.path)
      end

      def self.exist_by_paths(paths)
        find_by_image_file_paths(paths).all.map { |image| image.path }
      end

      def consistent_with?(image)
        path == image.path
      end

      def to_simple
        PhotoFS::Core::Image.new path
      end

      def update_from(image)
        self.path = image.path

        self
      end

    end
  end
end
