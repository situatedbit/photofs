module PhotoFS
  class Tag
    attr_reader :name

    def initialize(name)
      @name = name
      @images = []
    end

    def ==(other)
      other.is_a?(Tag) && (hash == other.hash)
    end

    def add(image)
      @images << image
    end

    def hash
      name.hash
    end

    def images
      @images
    end

    def intersection(other_images)
      return [] if images.empty? || other_images.empty?

      images & other_images
    end

    alias_method :eql?, :==
  end
end
