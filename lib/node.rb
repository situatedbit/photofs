module PhotoFS
  class Node
    attr_accessor :parent
    attr_reader :name

    def initialize(name, parent = nil)
      raise ArgumentError.new('node parent must be a directory') unless (parent.nil? || parent.directory?)

      raise ArgumentError.new('node name cannot be empty') if (name.nil? || name.empty?)

      @name = name
      @parent = parent
    end

    def ==(other)
      self.equal?(other) || (other.respond_to?(:path) && self.path == other.path)
    end

    def directory?
      false
    end

    def path
      return ::File::SEPARATOR + name if parent.nil?

      parent.path + ::File::SEPARATOR + name
    end

    def stat
      nil
    end
  end
end
