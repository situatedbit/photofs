module PhotoFS
  class Image
    def initialize(path)
      @path = path
    end

    def id
      @path
    end
  end
end
