require 'photofs/fs/normalized_path'

module PhotoFS
  module FS
    class FileMonitor
      def initialize(options)
        raise ArgumentError unless options.has_key?(:search_path) && options.has_key?(:images_root_path) && options.has_key?(:file_system)

        @fs = options[:file_system]
        @search_path = options[:search_path]
        @images_root_path = options[:images_root_path]
      end

      def paths
        glob.map do |path|
          real_path = @fs.join(@search_path, path)

          PhotoFS::FS::NormalizedPath.new(root: @images_root_path, real: real_path).to_s
        end
      end

      private

      def glob
        @fs.chdir(@search_path) do # restores process working dir when block completes
          @fs.glob("**/*.{cr2,gif,jpg,jpeg,png,psd,raf,tiff,tif,xcf,webp}", @fs.fnm(:casefold))
        end
      end
    end
  end
end
