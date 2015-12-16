require 'rfusefs'

class PhotoDir
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

  def unmount(message=nil)
    puts "#{message}\n" if message

    FuseFS.umount(@mountpoint)
  end

  public
  def contents(path)
    log "contents #{path}"
    Dir.entries(@root)
  end

  def directory?(path)
    log "directory? #{path}"
    File.directory?("#{@root}#{path}")
  end

  def file?(path)
    log "file? #{path}"
    File.exist? "#{@root}#{path}"
  end

  def read_file(path)
    log "read_file #{path}"
    ""
  end

  def log(s)
    puts s
  end
end

MY_OPTIONS = [:root]
OPTION_USAGE = " -o root=path/to/photos/"

# Usage: #{$0} mountpoint [mount_options] -o root=/path/to/photos
FuseFS.main(ARGV, MY_OPTIONS, OPTION_USAGE, nil, $0) do |options| 
  PhotoDir.new options
end
