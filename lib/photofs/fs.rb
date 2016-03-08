require 'photofs/fs/local'

module PhotoFS
  module FS
    DATA_DIR = '.photofs'

    def self.app_root
      ::File.join ::File.dirname(__FILE__), '..', '..'
    end

    def self.data_path(base_path = '')
      path = ::File.join(base_path, DATA_DIR)

      unless file_system.exist?(path) && file_system.directory?(path)
        file_system.mkdir(path)
      end

      path
    end

    def self.db_config_path
       ::File.join app_root, 'db'
    end

    def self.file_system
      PhotoFS::FS::Local.new
    end

    def self.migration_paths
      [::File.join(db_config_path, 'migrate')]
    end
  end
end
