require 'active_record'
require 'photofs/data'
require 'photofs/data/tag_binding'

module PhotoFS
  module Data
    class Tag < ActiveRecord::Base
      has_many :tag_bindings, dependent: :delete_all
      has_many :images, through: :tag_bindings

      validates :name, presence: true
      validates :name, uniqueness: true

      # Assumption: tag's images have already been created and are in the database
      # If they aren't, we raise an exception.
      def self.new_from_tag(tag)
        Tag.new.update_from(tag)
      end

      def consistent_with?(object)
        name == object.name && PhotoFS::Data.consistent_arrays?(images, object.images)
      end

      def update_from(tag_object)
        self.name = tag_object.name

        self.images = Tag.image_records_from(tag_object.images)

        self
      end

      private
      def self.image_records_from(images)
        images.map do |i|
          record = Image.from_image(i)

          raise InvalidImageError.new(i) unless record

          record
        end
      end

      public

      class InvalidImageError < ArgumentError
        def initialize(image_object)
          super "Image with path #{image_object.path} is not in the database"
        end
      end

    end
  end
end
