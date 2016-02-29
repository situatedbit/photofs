require 'photofs/core/image_set'
require 'photofs/data/image'

module PhotoFS
  module Data
    class ImageSet < PhotoFS::Core::ImageSet

      def initialize()
        @cache = Set.new

        super
      end

      def add(image)
# insert into db
      end

      def empty?
# db any?
      end

      def find_by_path(path)
# db query find by path (be sure to return nil if none)
      end

      protected

      def set
# all images as simple objects in a set
      end


    end
  end
end
