require 'active_record'
require 'erb'
require 'photofs/fs'

module PhotoFS
  module Data
    module Database
      class Connection
        include ActiveRecord::Tasks

        def initialize(db_path = '')
          @config = config_file
          @env = 'production'
          @config[@env]['database'] = ::File.join(db_path, 'photofs.sqlite3') unless db_path.empty?
          @current_config = @config[@env]

          ActiveRecord::Base.configurations = @config
        end

        def connect
          ActiveRecord::Base.establish_connection @current_config

          self
        end

        def ensure_schema
          configure_db_tasks

          if fs.exist?(@current_config['database'])
            DatabaseTasks.migrate
          else
            DatabaseTasks.create_current(@env)
            DatabaseTasks.load_schema_current(:ruby)
          end

          self
        end

        private

        def config_file
          @config_file ||= YAML::load(ERB.new(IO.read(::File.join(PhotoFS::FS.config_path, 'database.yml'))).result)
        end

        def configure_db_tasks
          DatabaseTasks.database_configuration = @current_config
          DatabaseTasks.db_dir = PhotoFS::FS.db_config_path
          DatabaseTasks.env = @env
          DatabaseTasks.root = PhotoFS::FS.app_root

          # ActiveRecord::Migrator paths are used when we load the schema;
          # DatabaseTasks migrations paths are used for the migrate method (above)
          DatabaseTasks.migrations_paths = PhotoFS::FS.migration_paths
          ActiveRecord::Migrator.migrations_paths = PhotoFS::FS.migration_paths
        end

        def fs
          PhotoFS::FS.file_system
        end

      end
    end
  end
end
