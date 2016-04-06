require 'photofs/fs/local'

module PhotoFS
  module FS
    DATA_DIR = '.photofs'

    def self.app_root
      ::File.join ::File.dirname(__FILE__), '..', '..'
    end

    def self.data_path
      @@data_path || nil
    end

    def self.data_path_join(*children)
      ::File.join(@@data_path, *children)
    end

    def self.db_config_path
       ::File.join app_root, 'db'
    end

    def self.find_data_parent_path(child_path)

      raise Errno::ENOENT if child_path == ::File::SEPARATOR

      return child_path if file_system.exist?(::File.join(child_path, DATA_DIR))

      return find_data_parent_path(::File.dirname(child_path))
    end

    def self.file_system
      @@fs ||= PhotoFS::FS::Local.new
    end

    def self.migration_paths
      [::File.join(db_config_path, 'migrate')]
    end

    def self.data_path_parent=(base_path)
      @@data_path = ::File.join(base_path, DATA_DIR)

      unless file_system.exist?(@@data_path) && file_system.directory?(@@data_path)
        file_system.mkdir(@@data_path)
      end

      @@data_path
    end
  end
end
