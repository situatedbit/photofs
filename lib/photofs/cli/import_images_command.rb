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
        @@_matcher ||= Parser.new [Parser::Pattern.new(['import', 'images', {paths: match_path}], expand_tail: true)]
      end

      def self.usage
        ['import images DIR_PATH...']
      end

      def after_initialize(args)
        @paths = parsed_args[:paths]
      end

      def datastore_start_path
        PhotoFS::FS.file_system.pwd
      end

      def modify_datastore
        paths_imported_count = 0

        @paths.each do |path|
          @output << "Importing images from \"#{path}\"..."

          file_monitor = PhotoFS::FS::FileMonitor.new({ images_root_path: PhotoFS::FS.images_path,
                                                        search_path: path,
                                                        file_system: PhotoFS::FS.file_system })

          # new up image set each time to drop references to previous
          # paths between #each loops and free resources.
          paths_imported = PhotoFS::Data::ImageSet.new.import! file_monitor.paths

          @output << paths_imported.map { |image| image.path }

          paths_imported_count += paths_imported.size
        end

        paths_imported_count > 0
      end

      def validate
        @paths = @paths.map { |path| valid_path path }
      end

      Command.register_command self
    end
  end
end
