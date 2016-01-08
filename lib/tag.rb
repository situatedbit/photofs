require_relative 'image_set'

module PhotoFS
  class Tag < ImageSet
    attr_reader :name

    def initialize(name)
      @name = name

      super
    end

    def ==(other)
      other.is_a?(Tag) && (hash == other.hash)
    end

    def hash
      name.hash
    end

# trying to resolve this method with ImageSet
# it returns an array; tag_set find_intersection depends on an array
# tag_dir file_images depends on that return
# if we make ImageSet an enumeration, then all of this resolves nicely
    def intersection(other_images)
      return [] if images.empty? || other_images.empty?

      images & other_images
    end

    alias_method :eql?, :==
    alias_method :all, :images
  end
end
