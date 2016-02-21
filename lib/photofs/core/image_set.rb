require 'set'

module PhotoFS
  module Core
    class ImageSet
      def initialize(options={})
        @options = default_options.merge options

        # parent and image_set should be mutually exclusive; either/or
        @set = @options[:set]
        @filter = @options[:filter]
        @parent = @options[:parent]
      end

      # new image set from cumulative intersection between this set and image_sets
      # takes either image set or an array of image sets
      def &(image_sets)
        image_sets = [image_sets].flatten #normalize to array

        return ImageSet.new if image_sets.empty?

        intersection = image_sets.reduce(range) do |memo, image_set|
          memo & image_set.to_set
        end

        ImageSet.new(:set => intersection)
      end

      def add(image)
        root_set << image
      end

      def find_by_path(path)
        # slow!
        range.each do |image|
          return image if image.path == path
        end

        return nil
      end

      def range
        domain.to_a.select { |i| @filter.call(i) }.to_set
      end

      def empty?
        range.empty?
      end

      def filter(&block)
        ImageSet.new(:filter => block, :parent => self)
      end

      def include? image
        range.include? image
      end

      def to_a
        range.to_a
      end

      def to_set
        Set.new range
      end

      alias_method :intersection, :&
      alias_method :<<, :add
      alias_method :images, :range
      alias_method :all, :range

      protected

      def root_set
        @parent ? @parent.root_set : @set
      end

      def local_set
        @set
      end

      private

      def default_options
        { :filter => Proc.new { |i| true },
          :parent => nil,
          :set => Set.new
        }
      end

      def domain
        @parent ? @parent.range : @set
      end
    end
  end
end
