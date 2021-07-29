require 'photofs/fs'
require 'yaml'

module PhotoFS
  module Config
    def self.load(options = { default: {} })
      begin
        YAML.load_file(File.expand_path(PhotoFS::FS::CONFIG_PATH))
      rescue
        options[:default]
      end
    end
  end
end
