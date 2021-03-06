require 'photofs/core/image_set'

module PhotoFS
  module Core
    class Tag < ImageSet
      attr_reader :name

      def initialize(name, options={})
        @name = name

        super options
      end

      def ==(other)
        other.is_a?(Tag) && (hash == other.hash)
      end

      def hash
        name.hash
      end

      def remove(images)
        images = [images].flatten # normalize as array

        images.each do |i|
          set.delete i
        end

        self
      end

      def to_s
        name
      end

      def_delegator :name, :<=>, :<=>
    end
  end
end
