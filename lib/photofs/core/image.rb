require 'photofs/core/image_name'

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

      # the path common to all variations of this image
      # e.g., |a/b/1984-06-23/1984-06-23-04|  .jpg
      # and   |a/b/1984-06-23/1984-06-23-04|  -small.xcf.jpg
      #             ^ this part
      def reference_path
          PhotoFS::Core::ImageName.reference_path path
      end

      def sidecar?(image)
        return (path != image.path) && (reference_path == image.reference_path)
      end

      def ==(other)
        other.is_a?(Image) && (hash == other.hash)
      end

      alias_method :eql?, :==
    end
  end
end
