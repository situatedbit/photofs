lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'photofs/fs'
require 'photofs/fuse'
require 'yaml'

begin
  config = YAML.load_file(File.expand_path(PhotoFS::FS::CONFIG_PATH))
rescue
  config = {}
end

PhotoFS::Fuse.mount config
