libdir = File.join(File.dirname(__FILE__), 'lib')
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require 'photofs/cli'

PhotoFS::CLI.parse(ARGV).execute
