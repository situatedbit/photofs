require 'rfuse'

class VirtualStat < RFuse::Stat
  DEFAULT_PERMISSIONS = 0400

  def initialize(real_file_abs_path)
    real_file_stat = File.stat(real_file_abs_path)

    # list of attributes
    attributes = [ :atime, :blksize, :blocks, :ctime, :dev, 
                   :gid, :ino, :mode, :mtime, :nlink, :rdev, 
                   :size, :uid ]

    attr_hash = {}

    attributes.map do | attribute |
      attr_hash[attribute] = real_file_stat.send attribute
    end

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

class PhotoFS
  attr_reader :root

  def initialize(options)
    raise RFuse::Error, "Missing root option (-o root=path)" unless options[:root]

    self.root = options[:root]

    @mountpoint = options[:mountpoint]
  end

  private
  def root=(value)
    raise RFuse::Error, "Root is not a directory (#{value})" unless File.directory?(value)

    @root = File.realpath(value)
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

MY_OPTIONS = [:root]
OPTION_USAGE = " -o root=path/to/photos/"

# Usage: #{$0} mountpoint [mount_options] -o root=/path/to/photos
RFuse.main(ARGV, MY_OPTIONS, OPTION_USAGE, nil, $0) do |options| 
  PhotoFS.new options
end
