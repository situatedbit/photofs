module PhotoFS
  class RelativePath
    def initialize(path)
      # normalize path to start with ./
      @path = '.' + separator + path.sub(/^(.$|\.\/|\/)/, '')
    end

    def ==(other)
      other.is_a?(RelativePath) && (hash == other.hash)
    end

    def follow_first
      return nil if is_this?

      RelativePath.new (['.'] + split[2..-1]).join(separator)
    end

    def first_name
      return nil if is_this?

      split[1]
    end

    def hash
      to_s.hash
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

    alias_method :eql?, :==

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
