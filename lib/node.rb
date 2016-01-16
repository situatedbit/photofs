module PhotoFS
  class Node
    attr_accessor :parent
    attr_reader :name

    def initialize(name, options={})
      @name = name
      @options = default_options.merge options
      @parent = @options[:parent]

      raise ArgumentError.new('node parent must be a directory') unless (@parent.nil? || @parent.directory?)
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

    private

    def default_options
      { :parent => nil }
    end
  end
end
