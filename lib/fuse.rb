require 'rfuse'
require_relative 'relative_path'
require_relative 'root_dir'
require_relative 'mirrored_dir'
require_relative 'tag_dir'
require_relative 'tag_set'

module PhotoFS
  class Fuse
    attr_reader :source_path

    def initialize(options)
      raise RFuse::Error, "Missing source option (-o source=path)" unless options[:source]

      @source_path = options[:source]
      @mountpoint = options[:mountpoint]

      tags = TagSet.new

      @root = RootDir.new
      @root.add MirroredDir.new('o', @source_path, {:tags => tags})
      @root.add TagDir.new('t', tags)
    end

    private
    def source_path=(value)
      raise RFuse::Error.new("Source is not a directory (#{value})") unless ::File.directory?(value)

      @source_path = File.realpath(value)
    end

    def search(path)
      log("search: #{path.to_s}")
      
      node = @root.search(path)

      raise Errno::ENOENT.new(path.to_s) if node.nil?

      node
    end

    public
    def readdir(context, path, filler, offset, ffi)
      log "readdir: #{path}"

      dir = search RelativePath.new(path)

      raise Errno::ENOTDIR.new(path) unless dir.directory?

      dir.nodes.each_pair { |name, node| filler.push(name, node.stat, 0) }
    end

    def getattr(context, path)
      log "stat: #{path}"

      path = RelativePath.new(path)

      Stat.new({:gid => context.gid, :uid => context.uid}, search(path).stat)
    end

    def readlink(context, path, size)
      log "readlink: #{path}, #{size.to_s}"

      search(RelativePath.new(path)).target_path
    end

    def mkdir(context, path, mode)
      log "mkdir: #{path}"

      path = RelativePath.new(path)

      search(path.parent).mkdir(path.name)
    end

    def rmdir(context, path)
      log "rmdir: #{path}"

      path = RelativePath.new(path)

      search(path.parent).rmdir(path.name)
    end

    def log(s)
      puts s
    end
  end

end # module
