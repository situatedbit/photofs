module PhotoFS
  module Fuse
    class Node
      attr_accessor :parent
      attr_reader :name

      def initialize(name, options={})
        @name = name
        @options = default_options.merge options
        @parent = @options[:parent]
        @payload = @options[:payload]

        raise ArgumentError.new('node parent must be a directory') unless (@parent.nil? || @parent.directory?)
      end

      def ==(other)
        self.equal?(other) || (other.respond_to?(:payload) && self.payload == other.payload)
      end

      def clear_cache
        # implemented by subclasses
      end

      def directory?
        false
      end

      def path
        return Fuse.fs.separator + name if parent.nil?

        Fuse.fs.join(parent.path, name)
      end

      # payload can be overwritten to store arbitrary objects for carriage
      # comparison between nodes is based on comparison between payloads
      def payload
        @payload || path
      end

      def stat
        nil
      end

      private

      def default_options
        { :parent => nil,
          :payload => nil }
      end
    end
  end
end
