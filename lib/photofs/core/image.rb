module PhotoFS
  module Core
    class Image
      # modifying path would break hashed storage based on path/name
      attr_reader :path

      def initialize(path)
        @path = path
      end

      def base_path
        # strip all extensions
        ::File.join [::File.dirname(path), ::File.basename(path).sub(/\..*$/, '')]
      end

      def hash
        path.hash
      end

      def name
        path.gsub(::File::SEPARATOR, '-').sub(/\A-/, '')
      end

      def sidecar?(image)
        return (path != image.path) && (base_path == image.base_path)
      end

      def ==(other)
        other.is_a?(Image) && (hash == other.hash)
      end

      alias_method :eql?, :==
    end
  end
end
