require 'photofs/fs'
require 'photofs/data/synchronize'
require 'photofs/data/database'

module PhotoFS
  module CLI
    class Command
      include PhotoFS::Data::Synchronize

      def self.register_command(command)
        @@commands ||= {}

        @@commands[command.matcher] = command

        @@usages ||= []

        @@usages << command.usage
      end

      def self.registered_commands
        @@commands || []
      end

      def self.command_usages
        @@usages || []
      end

      def initialize(args)
        @args = args

        after_initialize args
      end

      def after_initialize(args)
      end

      def file_system
        PhotoFS::FS.file_system
      end

      def initialize_datastore(data_path_subpath)
        PhotoFS::FS.data_path_parent = PhotoFS::FS.find_data_parent_path data_path_subpath

        PhotoFS::Data::Database::Connection.new(PhotoFS::FS.data_path).connect.ensure_schema
      end

      def valid_path(path)
        unless file_system.exist?(path) && file_system.realpath(path)
          raise Errno::ENOENT, path
        end

        file_system.realpath path
      end

      class CommandException < Exception
      end

      module MatcherTemplates
        def match_path
          '(\/)?([^\/\0]+(\/)?)+'
        end
      end

    end

  end
end
