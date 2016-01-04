module PhotoFS
  class Tag
    attr_reader :name

    def initialize(name)
      @name = name
      @images = {}
    end

    public

    def add(image)
      @images[image.id] = image
    end

    def images
      @images.values
    end
  end
end
