lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'photofs/fuse'

PhotoFS::Fuse.mount
