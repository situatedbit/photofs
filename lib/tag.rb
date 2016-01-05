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

    def intersection(other_images)
      return [] if images.empty? || other_images.empty?

      images.select { |image| other_images.include? image }
    end
  end
end
