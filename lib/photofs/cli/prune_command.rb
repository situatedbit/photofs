require 'photofs/cli'
require 'photofs/cli/command'
require 'photofs/fs'

module PhotoFS
  module CLI
    class PruneCommand < Command
      extend Command::MatcherTemplates

      def self.matcher
        @@_matcher ||= Parser.new([Parser::Pattern.new(['prune', {:path => "(/)|#{match_path}"}])])
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
        images = @images.find_by_path_parent @prune_path

        missing_images = images.select { |image| !fs.exist?(image.path) }

        missing_images.each do |image|
          @images.remove image
        end

        puts missing_images.empty? ? "No images to prune" : missing_images.map { |i| "Pruned #{i.path}" }.join("\n")

        !missing_images.empty?
      end

      def validate
        @prune_path = PhotoFS::FS.nearest_dir valid_path(@args_path)
      end

      private

      def fs
        @_fs = PhotoFS::FS.file_system
      end

      Command.register_command self
    end
  end
end
