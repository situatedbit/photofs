module PhotoFS
  class Image
    attr_reader :path

    def initialize(path)
      @path = path
    end

    def hash
      path.hash
    end

    def ==(other)
      other.is_a?(Image) && (hash == other.hash)
    end

    alias_method :eql?, :==
  end
end
