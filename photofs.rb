require 'rfuse'

require_relative 'lib/mirrored_dir'

=begin
class Fuse
  readdir
    node = find(path)
    if node.directory?
      node.entries.each { ... entry.name, entry.stat, ... }

  readlink
    node = top_level_dir(path).find(path)
    if node.link?
      node.target
end

# file < node
  # target

# mirror-dir < dir
# categories-dir < dir

=end
=begin
class VirtualStat < RFuse::Stat
  DEFAULT_PERMISSIONS = 0000400 # read only by owner

  def initialize(real_file_abs_path)
    attr_hash = PhotoFS::Stat.stat_hash(File.stat(real_file_abs_path))

    if File.directory? real_file_abs_path
      type = RFuse::Stat::S_IFDIR
    else
      # make the file a symbolic link to the real file
      type = RFuse::Stat::S_IFLNK
      attr_hash[:mode] = RFuse::Stat::S_IFLNK | DEFAULT_PERMISSIONS
      attr_hash[:nlink] = 1
      attr_hash[:size] = real_file_abs_path.length
    end

    super(type, DEFAULT_PERMISSIONS, attr_hash)
  end
end
=end
module PhotoFS
  class Fuse
    attr_reader :source_path

    def initialize(options)
      raise RFuse::Error, "Missing source option (-o source=path)" unless options[:source]

      @source_path = options[:source]
      @mountpoint = options[:mountpoint]

      @root = Dir.new('', nil)
      @root.add MirroredDir.new('o', @source_path)
    end

    private
    def source_path=(value)
      raise RFuse::Error, "Source is not a directory (#{value})" unless ::File.directory?(value)

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

      dir.nodes.each do |n| 
        puts n.name, n.stat
        filler.push(n.name, n.stat, 0)
      end
    end

    def getattr(context, path)
      log "stat: #{path}"

      search(path).stat
    end

    def readlink(context, path, size)
      log "readlink: #{path}, #{size.to_s}"

      search(path).target_path
    end

    def log(s)
      puts s
    end
  end

end # module

MY_OPTIONS = [:source]
OPTION_USAGE = " -o source=path/to/photos/"

# Usage: #{$0} mountpoint [mount_options] -o source=/path/to/photos
RFuse.main(ARGV, MY_OPTIONS, OPTION_USAGE, nil, $0) do |options| 
  PhotoFS::Fuse.new options
end
