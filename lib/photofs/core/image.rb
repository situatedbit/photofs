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
        #                        normalized name                 | irregular name
        match = basename.match /(\d{4}-\d{1,2}-\d{1,2}[a-z]*-\d+)|(\d+)$/

        # if no match, reference name is basename. If match, it's either normalized or irregular
        reference_name = match.nil? ? basename : (match[1] || match[2])

        ::File.join [::File.dirname(path), reference_name]
      end

      def sidecar?(image)
        return (path != image.path) && (reference_path == image.reference_path)
      end

      def ==(other)
        other.is_a?(Image) && (hash == other.hash)
      end

      alias_method :eql?, :==

      private
      def basename
        ::File.basename(path, extensions)
      end

      def extensions
        match = /^\.?[^.]+(\..+)/.match(path)

        match ? match[1] : ''
      end
    end
  end
end
