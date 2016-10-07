require 'photofs/fs'

module PhotoFS
  module FS
    class RelativePath
      def initialize(path)
        # normalize path to start with the first component, stripping leading slashes or ./ or .
        @path = path.sub(/^(\.$|\.\/|\/)/, '').strip
      end

      def ==(other)
        other.is_a?(RelativePath) && (hash == other.hash)
      end

      def descend
        return nil if is_this?

        RelativePath.new split[1..-1].join(separator)
      end

      def top_name
        return nil if is_this?

        split[0]
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
        split.length == 0
      end

      def is_name?
        split.length == 1
      end

      alias_method :eql?, :==

      private 
      def components
        @components ||= split.select { |c| c.length }
      end

      def length
        components.length
      end

      def separator
        PhotoFS::FS.file_system.separator
      end

      def split
        @split ||= @path.split(separator)
      end
    end
  end
end
