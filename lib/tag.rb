module PhotoFS
  class Tag
    attr_reader :name

    def initialize(name)
      @name = name
      @images = []
    end

    public

    def add(image)
      @images << image
    end

    def images
      @images
    end

    def intersection(other_images)
      return [] if images.empty? || other_images.empty?

      images & other_images
    end

  end
end
