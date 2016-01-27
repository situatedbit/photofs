require_relative 'image_set'

module PhotoFS
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
      images.each do |i|
        local_set.delete i
      end

      self
    end
  end
end
