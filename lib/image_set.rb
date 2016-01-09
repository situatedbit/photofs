module PhotoFS
  class ImageSet
    def initialize(image_set=nil)
      @set = image_set ? image_set.to_set : Set.new
    end

    def add(image)
      @set << image
    end

    def all
      @set.to_a
    end

    # new image set from cumulative intersection between this set and image_sets
    # takes either image set or an array of image sets
    def &(image_sets)
      image_sets = [image_sets].flatten #normalize to array

      return ImageSet.new if image_sets.empty?

      intersection = image_sets.reduce(@set) do |memo, image_set|
        memo & image_set.to_set
      end

      ImageSet.new intersection
    end

    def empty?
      @set.empty?
    end

    def to_set
      Set.new @set
    end

    alias_method :intersection, :&
    alias_method :<<, :add
    alias_method :images, :all
  end
end
