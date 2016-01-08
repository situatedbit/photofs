module PhotoFS
  class ImageSet
    attr_reader

    def initialize()
      @images_hash = {}
    end

    def add(image)
      @images_hash[image.name] = image
    end

    def all
      @images_hash.values
    end

    def &(image_sets)
      image_sets = [image_sets].flatten

      result_image_set = ImageSet.new

      unless @images_hash.empty? || image_sets.empty?
        intersection = image_sets.reduce(images.to_set) do |memo, tag| 
          memo & tag.images.to_set
        end

        intersection.each { |image| result_image_set << image }
      end

      result_image_set
    end

    def empty?
      @images_hash.empty?
    end

    alias_method :intersection, :&
    alias_method :<<, :add
    alias_method :images, :all
  end
end
