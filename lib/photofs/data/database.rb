require 'active_record'

# Database::Connection: connect ActiveRecord to the production database
# without having to refer to the standard Rails db/config.yml file.

# Tests are likely to continue to rely on the Rails config file. This is currently
# only designed for the non-test case.
module PhotoFS
  module Data
    module Database
      class Connection
        include ActiveRecord::Tasks

        attr_reader :env, :config, :db_dir, :app_root, :migration_paths

        def initialize(options={})
          @options = default_options.merge options

          @app_root = @options[:app_root]
          @config = @options[:config]
          @db_dir = @options[:db_dir]
          @env = @options[:env]
          @migration_paths = @options[:migration_paths]
        end

        # Assumes the database has been created, but still requires the schema
        def create_schema
          configure_tasks

          DatabaseTasks.load_schema_current :ruby

          self
        end

        def connect
          ActiveRecord::Base.configurations = config
          ActiveRecord::Base.establish_connection current_config

          self
        end

        def current_config
          config[env.to_s]
        end

        # Assumes the schema has been loaded at some point. Runs any outstanding
        # migrations on the database.
        def ensure_schema
          configure_tasks

          DatabaseTasks.migrate

          self
        end

        private

        def configure_tasks
          DatabaseTasks.database_configuration = current_config
          DatabaseTasks.db_dir = db_dir
          DatabaseTasks.env = env.to_s
          DatabaseTasks.root = app_root

          # ActiveRecord::Migrator paths are used when we load the schema;
          # DatabaseTasks migrations paths are used for the migrate method
          DatabaseTasks.migrations_paths = migration_paths
          ActiveRecord::Migrator.migrations_paths = migration_paths
        end

        def default_options
          {
            env: :production,
            config: {},
            db_dir: '',
            app_root: '',
            migration_paths: []
          }
        end
      end
    end
  end
end
