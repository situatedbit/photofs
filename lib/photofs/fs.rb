require 'photofs/fs/local'

module PhotoFS
  module FS
    DATA_DIR = '.photofs'

    def self.app_root
      ::File.join ::File.dirname(__FILE__), '..', '..'
    end

    def self.db_path
       ::File.join app_root, 'db'
    end

    def self.file_system
      PhotoFS::FS::Local.new
    end

    def self.migration_paths
      [::File.join(db_path, 'migrate')]
    end
  end
end
