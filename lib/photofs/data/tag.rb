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

      def self.from_tag(tag)
        Tag.find_by :name => tag.name
      end

      # Assumption: tag's images have already been created and are in the database
      # Any images not in the database will be omitted from the Data::Tag object
      # created here.
      def self.new_from_tag(tag)
        Tag.new.update_from(tag)
      end

      def consistent_with?(object)
        name == object.name && PhotoFS::Data.consistent_arrays?(images, object.images)
      end

      def to_simple
        tag = PhotoFS::Core::Tag.new name

        images.each do |image_record|
          tag.add image_record.to_simple
        end

        tag
      end

      def update_from(tag_object)
        self.name = tag_object.name

        self.images = Image.from_images tag_object.images

        self
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
