require 'rfuse'
require 'lib/node'
require 'lib/stat'

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

module PhotoFS

  class PhotoFS
    attr_reader :root

    def initialize(options)
      raise RFuse::Error, "Missing root option (-o root=path)" unless options[:root]

      self.root = options[:root]

      @mountpoint = options[:mountpoint]
      @top_nodes = { :o -> MirrorDir.new('o', self.root) }
    end

    private
    def root=(value)
      raise RFuse::Error, "Root is not a directory (#{value})" unless File.directory?(value)

      @root = File.realpath(value)
    end

    def find(path)
      
    end

    public
    def readdir(context, path, filler, offset, ffi)
      log "readdir: #{path}"
      full_path = File.absolute_path(@root + path)

      raise Errno::ENOTDIR.new(full_path) unless File.directory? full_path

      Dir.entries(full_path).each do |entry|
        filler.push(entry, VirtualStat.new(full_path), 0)
      end
    end

    def getattr(context, path)
      log "stat: #{path}"

      VirtualStat.new(File.absolute_path(@root + path))
    end

    def readlink(context, path, size)
      log "readlink: #{path}, #{size.to_s}"

      File.absolute_path(@root + path)[0, size]
    end

    def log(s)
      puts s
    end
  end

end # module

MY_OPTIONS = [:root]
OPTION_USAGE = " -o root=path/to/photos/"

# Usage: #{$0} mountpoint [mount_options] -o root=/path/to/photos
RFuse.main(ARGV, MY_OPTIONS, OPTION_USAGE, nil, $0) do |options| 
  PhotoFS::PhotoFS.new options
end
