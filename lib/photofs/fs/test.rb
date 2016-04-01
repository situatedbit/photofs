# Allows for stubbing local file system in integration tests
module PhotoFS::FS
  class Test < Local
    def initialize(file_system = {})
      @dirs = file_system[:dirs] || []
      @files = file_system[:files] || []
      @absolute_paths = file_system[:absolute_paths] || {}

      @stats = file_system[:stats] || {}
    end

    def absolute_path(path)
      @absolute_paths[path] || path
    end

    def add(fs_mapping)
      @dirs = @dirs + fs_mapping[:dirs] if fs_mapping.has_key? :dirs
      @files = @files + fs_mapping[:files] if fs_mapping.has_key? :files
      @absolute_paths = @absolute_paths.merge(fs_mapping[:absolute_paths]) if fs_mapping.has_key? :absolute_paths

      @stats = @stats.merge(fs_mapping[:stats]) if fs_mapping.has_key? :stats

      self
    end

    def directory?(path)
      @dirs.include? path
    end

    def entries(path)
      return nil if !exist?(path) || !directory?(path)

      children = all.select do |candidate|
        candidate != path && candidate.start_with?(path) && candidate.sub(path, '').start_with?('/')
      end

      e = ['.', '..'] + children.map do |child_path|
        trimmed = child_path.sub(path, '')
        trimmed.match(/\A\/([^\/]+)/)[1]
      end

      e.uniq
    end

    def exist?(path)
      all.include? path
    end

    def expand_path(path)
      path
    end

    def mkdir(path, mode = 0777)
      @dir << path
    end

    def stat(path)
      stat = @stats[path]

      if stat.nil?
        if @dirs.include? path
          stat = RFuse::Stat.directory(0, {})
        elsif @files.include? path
          stat = RFuse::Stat.file(0, {})
        else
          stat = nil
        end
      end

      stat
    end

    private

    def all
      @dirs + @files
    end

  end
end
