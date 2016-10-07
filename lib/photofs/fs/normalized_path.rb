require 'photofs/fs'
require 'photofs/fs/relative_path'

module PhotoFS
  module FS
    class NormalizedPath
      attr_accessor :raw, :root

      def initialize(raw_path, options = {})
        @root = options[:root] || PhotoFS::FS.images_path
        @fs = options[:file_system] || PhotoFS::FS.file_system

        @raw = raw_path
      end

      def path
        begin
          realpath = @fs.realpath(raw)
        rescue Exception
          raise NormalizedPathException
        end

        raise NormalizedPathException unless realpath.start_with?(root)

        RelativePath.new realpath.sub(root, '')
      end

      def to_s
        path.to_s
      end
    end

    class NormalizedPathException < Exception
    end
  end
end
