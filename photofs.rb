require 'rfuse'
require_relative 'lib/fuse'

MY_OPTIONS = [:source]
OPTION_USAGE = " -o source=path/to/photos/"

# Usage: #{$0} mountpoint [mount_options] -o source=/path/to/photos
RFuse.main(ARGV, MY_OPTIONS, OPTION_USAGE, nil, $0) do |options| 
  PhotoFS::Fuse.new options
end
