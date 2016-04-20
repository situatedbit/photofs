require 'set'

module PhotoFS
  module Core
    class ImageSet
      def initialize(options={})
        @options = default_options.merge options

        @set = @options[:set]
      end

      # new image set from cumulative intersection between this set and image_sets
      # takes either image set or an array of image sets
      def &(image_sets)
        image_sets = [image_sets].flatten #normalize to array

        return ImageSet.new if image_sets.empty?

        intersection = image_sets.reduce(set) do |memo, image_set|
          memo & image_set.to_set
        end

        ImageSet.new(:set => intersection)
      end

      def add(image)
        set << image
      end

      def empty?
        set.empty?
      end

      def find_by_path(path)
        set.each do |image|
          return image if image.path == path
        end

        return nil
      end

      def find_by_paths(paths)
        Hash[paths.map { |p| [p, find_by_path(p)] }]
      end

      def include?(image)
        set.include? image
      end

      def to_a
        set.to_a
      end

      def to_set
        Set.new set
      end

      alias_method :intersection, :&
      alias_method :<<, :add
      alias_method :images, :to_a
      alias_method :all, :to_a

      protected

      def set
        @set
      end

      private

      def default_options
        { :set => Set.new }
      end

    end
  end
end
