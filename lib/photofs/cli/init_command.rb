require 'photofs/cli'
require 'photofs/cli/command'
require 'photofs/cli/command_validators'
require 'photofs/fs'

module PhotoFS
  module CLI
    class InitCommand < Command
      extend Command::MatcherTemplates
      include CommandValidators

      def self.matcher
        @@_matcher ||= Parser.new [Parser::Pattern.new(['init', {path: match_path}])]
      end

      def self.usage
        ['init PATH']
      end

      def after_initialize(args)
        @path = parsed_args[:path]
      end

      def datastore_start_path
        @path
      end

      def initialize_datastore(data_subpath)
        PhotoFS::FS.data_path_parent = PhotoFS::FS.find_data_parent_path data_subpath

        options = {
          app_root: PhotoFS::FS.app_root,
          config: PhotoFS::FS.data_config,
          db_dir: PhotoFS::FS.db_dir,
          migration_paths: PhotoFS::FS.migration_paths
        }

        PhotoFS::Data::Database::Connection.new(options).connect.create_schema
      end

      def modify_datastore
        # no op
        true
      end

      def validate
        @path = valid_path @path
      end

      Command.register_command self
    end
  end
end
