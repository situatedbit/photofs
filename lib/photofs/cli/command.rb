require 'photofs/cli/parser'
require 'photofs/data/synchronize'
require 'photofs/data/database'

module PhotoFS::CLI
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

        PhotoFS::Data::Synchronize.read_write_lock.grab do |lock|
          lock.increment_count if modify_datastore
        end
      rescue => e
        puts e.message
      end
    end

    def initialize_datastore(data_path_subpath)
      PhotoFS::FS.data_path_parent = PhotoFS::FS.find_data_parent_path data_path_subpath

      PhotoFS::Data::Database::Connection.new(PhotoFS::FS.data_path).connect.ensure_schema
    end

    def modify_datastore
      raise NotImplementedError
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
