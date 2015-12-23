module PhotoFS
  class Node
    attr_accessor :parent
    attr_accessor :name

    def initialize(name, parent = nil)
      raise ArgumentError.new('node parent must be a directory') unless (parent.nil? || parent.directory?)

      raise ArgumentError.new('node name cannot be empty') if (name.nil? || name.empty?)

      @name = name
      @parent = parent
    end

    def directory?
      false
    end

    def path
      return File::SEPARATOR + name if parent.nil?

      parent.path + File::SEPARATOR + name
    end

    def stat
      nil
    end
  end
end
