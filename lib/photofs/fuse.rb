require_relative 'fuse/fuse'

module PhotoFS
  module Fuse
    MY_OPTIONS = [:daemon, :source]
    OPTION_USAGE = " -o source=path/to/photos/"

    # Usage: #{$0} mountpoint [mount_options] -o source=/path/to/photos
    def self.mount
      RFuse.main(ARGV, MY_OPTIONS, OPTION_USAGE, nil, $0) do |options|
        Process.daemon(true) if options[:daemon]

        PhotoFS::Fuse::Fuse.new options
      end
    end

  end
end
