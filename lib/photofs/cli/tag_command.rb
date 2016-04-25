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
        /tag [^\/\0]+ #{match_path}/
      end

      def self.usage
        'tag TAG IMAGE_PATH'
      end

      def after_initialize(args)
        @args_tag_name = args[1]
        @args_image_path = args[2]

        @images = PhotoFS::Data::ImageSet.new
        @tags = PhotoFS::Data::TagSet.new        
      end

      def datastore_start_path
        @real_image_path
      end

      def modify_datastore
        image = @images.find_by_path @real_image_path

        raise(CommandException, error_message) unless image

        tag = @tags.find_by_name(@args_tag_name) || @tags.add?(PhotoFS::Core::Tag.new @args_tag_name)

        tag.add image

        @images.save!
        @tags.save!

        return true
      end

      def validate
        @real_image_path = valid_path @args_image_path
      end

      private

      def error_message
        "#{@real_image_path} is not a registered image. Import the image first."
      end

      Command.register_command self
    end
  end
end
