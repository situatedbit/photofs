require 'photofs/cli'
require 'photofs/cli/command'
require 'photofs/core/tag'
require 'photofs/data/image_set'
require 'photofs/data/tag_set'

module PhotoFS
  module CLI
    class TagCommand < Command
      extend Command::MatcherTemplates

      def self.matcher
        @@_matcher ||= Parser.new([Parser::Pattern.new(['tag', {:tag => match_tag}, {:paths => match_path}], :expand_tail => true)])
      end

      def self.usage
        'tag TAG IMAGE_PATH'
      end

      def after_initialize(args)
        @args_tag_name = parsed_args[:tag]
        @args_image_paths = parsed_args[:paths]

        @images = PhotoFS::Data::ImageSet.new
        @tags = PhotoFS::Data::TagSet.new        
      end

      def datastore_start_path
        @real_image_paths.first
      end

      def modify_datastore
        images = @real_image_paths.map { |path| @images.find_by_path(path) || raise(CommandException, error_message) }

        images.each do |image|
          tag = @tags.find_by_name(@args_tag_name) || @tags.add?(PhotoFS::Core::Tag.new @args_tag_name)

          tag.add image

          @images.save!
          @tags.save!
        end

        return true
      end

      def validate
        @real_image_paths = @args_image_paths.map { |path| valid_path path }
      end

      private

      def error_message
        "#{@real_image_path} is not a registered image. Import the image first. No images were tagged."
      end

      Command.register_command self
    end
  end
end
