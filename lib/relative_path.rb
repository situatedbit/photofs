module PhotoFS
  class RelativePath
    def initialize(path)
      @path = path.sub(/^\.?\/?/, '.' + separator)
    end

    def follow_first
      return nil if is_this?

      RelativePath.new (['.'] + split[2..-1]).join(separator)
    end

    def first_name
      return nil if is_this?

      split[1]
    end

    def name
      is_this? ? '' : components.last
    end

    def parent
      return nil if is_this?

      RelativePath.new(split[0..-2].join(separator))
    end

    def to_s
      @path
    end

    def is_this?
      split.length == 1
    end

    private 
    def components
      @components ||= split.select { |c| c.length > 0 && c != '.' }
    end

    def length
      components.length
    end

    def separator
      ::File::SEPARATOR
    end

    def split
      @split ||= @path.split(separator)
    end
  end
end
