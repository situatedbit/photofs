require 'photofs/cli'
require 'photofs/cli/command'
require 'photofs/cli/command_validators'
require 'photofs/core/image'
require 'photofs/fs'
require 'photofs/fs/file_monitor'

module PhotoFS
  module CLI
    class ImportImagesCommand < Command
      extend Command::MatcherTemplates
      include CommandValidators

      def self.matcher
        @@_matcher ||= Parser.new [Parser::Pattern.new(['import', 'images', {path: match_path}])]
      end

      def self.usage
        ['import images DIR_PATH']
      end

      def after_initialize(args)
        @path = parsed_args[:path]

        @images = PhotoFS::Data::ImageSet.new
      end

      def datastore_start_path
        PhotoFS::FS.file_system.pwd
      end

      def modify_datastore
        @output << "Importing images from \"#{@path}\"..."

        file_monitor = PhotoFS::FS::FileMonitor.new({ images_root_path: PhotoFS::FS.images_path,
                                                      search_path: @path,
                                                      file_system: PhotoFS::FS.file_system })

        paths_imported = @images.import! file_monitor.paths

        @output += paths_imported.map { |image| image.path }

        !paths_imported.empty?
      end

      def validate
        @path = valid_path @path
      end

      Command.register_command self
    end
  end
end
