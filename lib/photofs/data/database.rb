require 'active_record'
require 'photofs/fs'

module PhotoFS
  module Data
    class Database
      include ActiveRecord::Tasks

      def initialize(env, db_path = '')
        @config = config_file
        @config[env]['database'] = ::File.join(db_path, 'photofs.sqlite3') unless db_path.empty?
        @current_config = @config[env]
        @env = env

        ActiveRecord::Base.configurations = @config
      end

      def connect
        ActiveRecord::Base.establish_connection @current_config

        self
      end

      def ensure_schema
        configure_db_tasks

        unless fs.exist?(@current_config['database'])
          DatabaseTasks.create_current(@env)
          DatabaseTasks.load_schema_current(:ruby)
        end

        DatabaseTasks.migrate

        self
      end

      private

      def config_file
        @config_file ||= YAML::load(IO.read(::File.join(PhotoFS::FS.app_root, 'config', 'database.yml')))
      end

      def configure_db_tasks
        DatabaseTasks.database_configuration = @current_config
        DatabaseTasks.db_dir = PhotoFS::FS.db_config_path
        DatabaseTasks.env = @env
        DatabaseTasks.migrations_paths = PhotoFS::FS.migration_paths
        DatabaseTasks.root = PhotoFS::FS.app_root
      end

      def fs
        PhotoFS::FS.file_system
      end

    end
  end
end
