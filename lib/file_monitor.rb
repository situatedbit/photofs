require_relative 'fuse'
require_relative 'image'

module PhotoFS
  class FileMonitor
    def initialize(root)
      @root = Fuse.fs.expand_path root
    end

    def paths
      glob.map { |path| Fuse.fs.join(@root, path) }
    end

    private

    def glob
      Fuse.fs.chdir(@root) do # restores process working dir when block completes
        Fuse.fs.glob("**/*.{jpg,jpeg}", Fuse.fs.fnm(:casefold))
      end
    end
  end
end
