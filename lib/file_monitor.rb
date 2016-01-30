require_relative 'image'

module PhotoFS
  class FileMonitor
    def initialize(root, image_set)
      @root = ::File.expand_path root
      @set = image_set
    end

    def paths
      glob.map { |path| ::File.join(@root, path) }
    end

    def scan
      paths.each do |image_path|
        if !@set.find_by_path(image_path)
          @set.add(Image.new(image_path))
        end
      end
    end

    private

    def glob
      ::Dir.chdir(@root) do # restores process working dir when block completes
        ::Dir.glob("**/*.{jpg,jpeg}", ::File::FNM_CASEFOLD)
      end
    end
  end
end
