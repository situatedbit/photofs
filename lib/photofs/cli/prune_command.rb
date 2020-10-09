require 'photofs/cli'
require 'photofs/cli/command'
require 'photofs/cli/command_validators'
require 'photofs/fs'
require 'photofs/fs/normalized_path'

module PhotoFS
  module CLI
    class PruneCommand < Command
      extend Command::MatcherTemplates
      include CommandValidators
      include PhotoFS::FS::FileSystem

      def self.matcher
        @@_matcher ||= Parser.new([Parser::Pattern.new(['prune', {path: "(/)|#{match_path}"}])])
      end

      def self.usage
        ['prune PATH where PATH is a directory or file in the image source directory tree']
      end

      def after_initialize(args)
        @args_path = parsed_args[:path]

        @images = PhotoFS::Data::ImageSet.new
      end

      def datastore_start_path
        @prune_path
      end

      def modify_datastore
        images = @images.find_by_path_parent PhotoFS::FS::NormalizedPath.new(root: PhotoFS::FS.images_path, real: @prune_path).to_s

        missing_images = images - existing_images(images)

        missing_images.each do |image|
          @images.remove image
        end

        @output << (missing_images.empty? ? "No images to prune" : missing_images.map { |i| "Pruned #{i.path}" }.join("\n"))

        !missing_images.empty?
      end

      def validate
        @prune_path = PhotoFS::FS.nearest_dir valid_path(@args_path)
      end

      private

      def existing_images(images_to_verify)
        images_to_verify.select do |image|
          file_system.exist? [PhotoFS::FS.images_path, image.path].join(file_system.separator)
        end
      end

      Command.register_command self
    end
  end
end
