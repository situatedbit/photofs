require 'application_record'

require 'photofs/data/file'
require 'photofs/core/image'

module PhotoFS
  class Image < ApplicationRecord
    belongs_to :image_file, { :autosave => true, :dependent => :destroy }

    has_many :tag_bindings, dependent: :delete_all

    scope :join_file, -> { joins(:image_file) }

    validates :image_file, presence: true
    validates :image_file_id, uniqueness: true

    def self.find_by_paths_start(paths)
      paths = [paths].flatten.map { |p| "#{p}%"} # normalize to array, add LIKE wildcard

      where_clause = paths.map { "files.path LIKE ?" }.join(' or ')

      Image.join_file.where(where_clause, *paths)
    end

    def self.find_by_image_file_paths(paths)
      Image.join_file.where('files.path in (?)', paths)
    end

    def self.find_by_path_parent(path)
      # if path isn't empty, must end with / to prevent selecting 2.jpg from 'some/path/1.jpg',
      #   'some/path-to-file/2.jpg' with path='some/path'
      path_filter = path.end_with?(::File::SEPARATOR) ? path : "#{path}#{::File::SEPARATOR}"
      join_scope = Image.join_file

      case path
        when '' then join_scope
        else join_scope.where('instr(files.path, (?)) == 1', path_filter)
      end
    end

    def self.find_by_sidecar_candidates(images)
      base_paths = images.map { |i| i.base_path }

      find_by_paths_start(base_paths)
    end

    def self.from_image(image)
      Image.join_file.where('files.path = ?', image.path).first
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
