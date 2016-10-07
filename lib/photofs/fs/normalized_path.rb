require 'photofs/fs/relative_path'

module PhotoFS
  module FS
    class NormalizedPath
      attr_accessor :real_path, :root_path, :path

      def initialize(options)
        raise ArgumentError unless options.has_key?(:real) && options.has_key?(:root)

        @root_path = options[:root]
        @real_path = options[:real]

        raise NormalizedPathException, "path '#{real_path}' is not within root path '#{root_path}'" unless real_path.start_with?(root_path)

        @path = RelativePath.new real_path.sub(root_path, '')
      end

      def to_s
        path.to_s
      end
    end

    class NormalizedPathException < Exception
    end
  end
end
