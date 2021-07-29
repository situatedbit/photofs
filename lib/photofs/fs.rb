require 'photofs/fs/local'
require 'yaml'

module PhotoFS
  module FS
    module FileSystem
      def file_system
        PhotoFS::FS.file_system
      end
    end

    DATA_DIR = '.photofs'
    CONFIG_DIR = '~/.photo-flow'
    CONFIG_PATH = ::File.join(CONFIG_DIR, 'config.yaml')

    def self.app_root
      ::File.join ::File.dirname(__FILE__), '..', '..'
    end

    # loads the database configuration structure from custom yaml file
    def self.data_config
      begin
        YAML.load file_system.read_file(::File.join(data_path, 'database.yml'))
      rescue Exception => e
        puts "Unable to load .photofs/database.yml. Here is a sample:"
        puts %{
production:
  adapter: mysql2
  encoding: utf8mb4
  collation: utf8mb4_bin
  database:
  username:
  password:
  host: 127.0.0.1
  port: 3306
}
        raise e
      end
    end

    def self.data_path
      images_path ? ::File.join(images_path, DATA_DIR) : nil
    end

    def self.data_path_join(*children)
      ::File.join(data_path, *children)
    end

    # ActiveRecord/Rails-specific database configurations; migrations, schema,
    # and default config file (at least for test environment)
    def self.db_dir
       ::File.join app_root, 'db'
    end

    def self.expand_path(normalized_path)
      [images_path, normalized_path.to_s].join(file_system.separator)
    end

    def self.find_data_parent_path(child_path)
      raise Errno::ENOENT, "could not find #{DATA_DIR} directory" if child_path == ::File::SEPARATOR

      return file_system.realpath(child_path) if file_system.exist?(::File.join(child_path, DATA_DIR))

      return find_data_parent_path(::File.dirname(child_path))
    end

    def self.file_system
      @@fs ||= PhotoFS::FS::Local.new
    end

    def self.images_path
      @@images_path || nil
    end

    def self.log_file
      data_path_join('log')
    end

    def self.nearest_dir(path)
      return path if path == ::File::SEPARATOR
      return path if file_system.directory? path
      return nearest_dir file_system.dirname(path)
    end

    def self.migration_paths
      [::File.join(db_dir, 'migrate')]
    end

    def self.data_path_parent=(base_path)
      @@images_path = base_path

      unless file_system.exist?(data_path) && file_system.directory?(data_path)
        file_system.mkdir(data_path)
      end

      data_path
    end
  end
end
