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
        total_import_count = 0

        @paths.each do |path|
          count = 0
          imports_since_gc = 0

          GC.start

          file_monitor = PhotoFS::FS::FileMonitor.new(
            images_root_path: PhotoFS::FS.images_path,
            search_path: path,
            file_system: PhotoFS::FS.file_system
          )

          # To mitigate resource use for potentially massive initial imports,
          # divide the list of import paths into smaller chunks, new up an image
          # set for each chunk, and explicitly call the garbage collector to
          # free up memory every few import chunks.
          paths_buffer_size = 4096
          file_monitor.paths.each_slice(paths_buffer_size) do |file_monitor_paths|
            count += (PhotoFS::Data::ImageSet.new.import! file_monitor_paths).size
            imports_since_gc += 1

            if imports_since_gc > 3
              GC.start
              imports_since_gc = 0
            end
          end

          @output << "#{path}: #{count} image#{count == 1 ? '' : 's'} imported"

          total_import_count += count
        end

        total_import_count > 0
      end

      def validate
        @paths = @paths.map { |path| valid_path path }
      end

      Command.register_command self
    end
  end
end
