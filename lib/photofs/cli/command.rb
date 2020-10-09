require 'photofs/cli/parser'
require 'photofs/data/synchronize'
require 'photofs/data/database'

module PhotoFS
  module CLI
    class Command
      include PhotoFS::Data::Synchronize

      def self.command_usages
        @@usages || []
      end

      def self.match?(argv)
        matcher.match?(argv)
      end

      def self.matcher
        raise NotImplementedError
      end

      def self.register_command(command)
        @@commands ||= []

        @@commands << command

        @@usages ||= []

        command.usage.each { |usage| @@usages << usage }
      end

      def self.registered_commands
        @@commands || []
      end

      def initialize(args)
        @args = args
        @output = []

        after_initialize args
      end

      def after_initialize(args)
        # optionally implemented by subclass
      end

      def datastore_start_path
        raise NotImplementedError
      end

      def execute
        begin
          validate

          initialize_datastore datastore_start_path

          PhotoFS::Data::Synchronize.write_lock.grab do |lock|
            lock.increment_count if modify_datastore
          end

          puts output
        rescue => e
          puts e.message
        end
      end

      def initialize_datastore(data_path_subpath)
        PhotoFS::FS.data_path_parent = PhotoFS::FS.find_data_parent_path data_path_subpath

        options = {
          app_root: PhotoFS::FS.app_root,
          config: PhotoFS::FS.data_config,
          db_dir: PhotoFS::FS.db_dir,
          migration_paths: PhotoFS::FS.migration_paths
        }

        PhotoFS::Data::Database::Connection.new(options).connect.ensure_schema
      end

      def modify_datastore
        raise NotImplementedError
      end

      def output
        @output.join "\n"
      end

      def parsed_args
        @parsed_args ||= self.class.matcher.parse(@args)
      end

      def validate
        # optionally implemented by subclass; throw exception if invalid
      end

      class CommandException < Exception
      end

      module MatcherTemplates
        def match_tag_list
          "#{match_tag}(\\s*#{match_tag})*"
        end

        def match_path
          '(\/)?([^\/\0]+(\/)?)+'
        end

        def match_tag
          '[^\s\/\0]+'
        end
      end

    end
  end
end
