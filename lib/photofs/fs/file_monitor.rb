require 'photofs/fs'

module PhotoFS
  module FS
    class FileMonitor
      def initialize(root)
        @fs = PhotoFS::FS.file_system
        @root = @fs.expand_path root
      end

      def paths
        glob.map { |path| @fs.join(@root, path) }
      end

      private

      def glob
        @fs.chdir(@root) do # restores process working dir when block completes
          @fs.glob("**/*.{jpg,jpeg,cr2}", @fs.fnm(:casefold))
        end
      end
    end
  end
end
