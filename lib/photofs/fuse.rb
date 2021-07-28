require 'photofs/fuse/fuse'

module PhotoFS
  module Fuse
    MY_OPTIONS = [:log, :daemon, :source]
    OPTION_USAGE = " -o source=path/to/photos/"

    # Usage: #{$0} mountpoint [mount_options] -o source=/path/to/photos
    def self.mount
      RFuse.main(ARGV, MY_OPTIONS, OPTION_USAGE, nil, $0) do |options|
        raise RuntimeError.new('Missing required source option') unless options.has_key?(:source)

        begin
          # get path before daemonizing, after which we'd lose CWD, relatives paths like ~
          options[:source] = ::File.realpath(::File.expand_path(options[:source]))
        rescue Errno::ENOENT
          raise "Source path does not exist: #{options[:source]}"
        end

        Process.daemon if options[:daemon]

        PhotoFS::Fuse::Fuse.new options
      end
    end

  end
end
