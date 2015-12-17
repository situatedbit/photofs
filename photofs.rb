require 'rfuse'

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
  def readdir(ctx, path, filler, offset, ffi)
    log "readdir: #{path}"
    full_path = @root + path

    raise Errno::ENOTDIR.new(full_path) unless File.directory? full_path

    Dir.entries(full_path).each do |entry|
      filler.push(entry, File.stat(full_path), 0)
    end
  end

  def getattr(ctx, path)
    log "stat: #{path}"
    File.stat(@root + path)
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
