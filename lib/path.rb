module PhotoFS
  class Path
    def initialize(path)
      @path = path

      raise ArgumentError.new("Path must be empty or start with #{::File::SEPARATOR}") unless @path.empty? || @path.start_with?(::File::SEPARATOR)
    end

    def components
      @components ||= split.select { |c| c.length > 0 }
    end

    def length
      components.length
    end

    def name
      components.last || ''
    end

    def parent_path
      length < 2 ? Path.new('') : Path.new(split[0..-2].join(::File::SEPARATOR))
    end

    def to_s
      @path
    end

    alias_method :to_a, :components

    private 
    def split
      @split ||= @path.split(::File::SEPARATOR)
    end
  end
end
