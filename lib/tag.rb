require_relative 'image_set'

module PhotoFS
  class Tag < ImageSet
    attr_reader :name

    def initialize(name, enum=nil)
      @name = name

      super enum
    end

    def ==(other)
      other.is_a?(Tag) && (hash == other.hash)
    end

    def hash
      name.hash
    end
  end
end
