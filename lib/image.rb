module PhotoFS
  class Image
    def initialize(path)
      @path = path
    end

    def id
      @path
    end

    def ==(other)
      other.is_a?(Image) && (id == other.id)
    end
  end
end
