module PhotoFS
  module Core
    class Image
      # modifying path would break hashed storage based on path/name
      attr_reader :path 

      def initialize(path)
        @path = path
      end

      def hash
        path.hash
      end

      def name
        path.gsub(::File::SEPARATOR, '-').sub(/\A-/, '')
      end

      def sidecar?(image)
        same_path = path == image.path
        same_dir = ::File.dirname(path) == ::File.dirname(image.path)
        same_basename = ::File.basename(path, '.*') == ::File.basename(image.path, '.*')

        return !same_path && same_dir && same_basename
      end

      def ==(other)
        other.is_a?(Image) && (hash == other.hash)
      end

      alias_method :eql?, :==
    end
  end
end
