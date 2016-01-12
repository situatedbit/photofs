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

      @root = RootDir.new
      @root.add MirroredDir.new('o', @source_path)
      @root.add TagDir.new('t', TagSet.new)
    end

    private
    def source_path=(value)
      raise RFuse::Error.new("Source is not a directory (#{value})") unless ::File.directory?(value)

      @source_path = File.realpath(value)
    end

    def search(path)
      log("search: #{path}")
      path_components = path.split ::File::SEPARATOR
      
      node = @root.search(path_components.slice(1, path_components.size) || [])

      raise Errno::ENOENT.new(path) if node.nil?

      node
    end

    public
    def readdir(context, path, filler, offset, ffi)
      log "readdir: #{path}"

      dir = search path

      raise Errno::ENOTDIR.new(path) unless dir.directory?

      dir.nodes.each { |n| filler.push(n.name, n.stat, 0) }
    end

    def getattr(context, path)
      log "stat: #{path}"

      Stat.new({:gid => context.gid, :uid => context.uid}, search(path).stat)
    end

    def readlink(context, path, size)
      log "readlink: #{path}, #{size.to_s}"

      search(path).target_path
    end

    def mkdir(context, path, mode)
      log "mkdir: #{path}"

      path_components = path.split ::File::SEPARATOR

      search(path_components[0..-2].join(::File::SEPARATOR)).mkdir(path_components.last)
    end

    def rmdir(context, path)
      log "rmdir: #{path}"

      path_components = path.split ::File::SEPARATOR

      search(path_components[0..-2].join(::File::SEPARATOR)).rmdir(path_components.last)
    end

    def log(s)
      puts s
    end
  end

end # module
