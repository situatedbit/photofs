require 'photofs/cli'
require 'photofs/cli/command'
require 'photofs/core/image'
require 'photofs/fs/file_monitor'

module PhotoFS
  module CLI
    class ImportCommand < Command
      extend Command::MatcherTemplates

      def self.matcher
        /import #{match_path}/
      end

      def self.usage
        'import DIR_PATH'
      end

      def after_initialize(args)
        @path = args[1]

        @images = PhotoFS::Data::ImageSet.new
      end

      def execute
        @path = valid_path @path

        initialize_datastore @path

        puts "Importing images from \"#{@path}\"..."

        PhotoFS::Data::Synchronize.read_write_lock.grab do |lock|
          @images.import PhotoFS::FS::FileMonitor.new(@path).paths

          lock.increment_count
        end

        puts "うわった, よ.\n"
      end

      Command.register_command self
    end
  end
end
