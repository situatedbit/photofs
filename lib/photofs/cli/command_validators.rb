require 'photofs/cli/command'
require 'photofs/fs'

module PhotoFS
  module CLI
    module CommandValidators
      def invalid_images_error_message(missing_paths)
        "Missing paths: \n" + missing_paths.join("\n")
      end

      def valid_images_from_paths(image_set, paths)
        image_path_pairs = image_set.find_by_paths(paths)

        non_imported_paths = image_path_pairs.keys.select { |path| image_path_pairs[path].nil? }

        raise(CommandValidationException, invalid_images_error_message(non_imported_paths)) unless non_imported_paths.empty?

        image_path_pairs.values
      end

      def valid_path(path)
        unless PhotoFS::FS.file_system.exist?(path) && PhotoFS::FS.file_system.realpath(path)
          raise Errno::ENOENT, path
        end

        PhotoFS::FS.file_system.realpath path
      end

      class CommandValidationException < Command::CommandException
      end
    end
  end
end
