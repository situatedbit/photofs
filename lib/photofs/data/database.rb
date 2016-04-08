require 'active_record'
require 'photofs/fs'

module PhotoFS
  module Data
    module Database
      module WriteCounter
        WRITE_COUNTER_FILE = 'database-writes'

        def database_write_counter
          path = PhotoFS::FS.data_path_join(WRITE_COUNTER_FILE)

          PhotoFS::FS.file_system.write_file(path, '0') unless PhotoFS::FS.file_system.exist?(path)

          contents = PhotoFS::FS.file_system.read_file(path)

          (contents.nil? || contents.empty?) ? 0 : Integer(contents)
        end

        def increment_database_write_counter
          path = PhotoFS::FS.data_path_join(WRITE_COUNTER_FILE)

          counter = database_write_counter + 1

          PhotoFS::FS.file_system.write_file(path, counter.to_s)

          counter
        end
      end # WriteCounter

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
          @config_file ||= YAML::load(IO.read(::File.join(PhotoFS::FS.db_config_path, 'config.yml')))
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
