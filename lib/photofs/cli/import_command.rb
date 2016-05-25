require 'photofs/cli'
require 'photofs/cli/command'
require 'photofs/core/image'
require 'photofs/fs/file_monitor'

module PhotoFS
  module CLI
    class ImportCommand < Command
      extend Command::MatcherTemplates

      def self.matcher
        @@_matcher ||= Parser.new [Parser::Pattern.new(['import', {:path => match_path}])]
      end

      def self.usage
        ['import DIR_PATH']
      end

      def after_initialize(args)
        @path = parsed_args[:path]

        @images = PhotoFS::Data::ImageSet.new
      end

      def datastore_start_path
        @path
      end

      def modify_datastore
        puts "Importing images from \"#{@path}\"..."

        paths_imported = @images.import PhotoFS::FS::FileMonitor.new(@path).paths

        puts "うわった, よ.\n"

        !paths_imported.empty?
      end

      def validate
        @path = valid_path @path
      end

      Command.register_command self
    end
  end
end