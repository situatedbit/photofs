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
  end
end
