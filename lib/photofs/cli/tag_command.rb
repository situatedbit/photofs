require 'photofs/cli'
require 'photofs/cli/command'
require 'photofs/core/tag'
require 'photofs/data/image_set'
require 'photofs/data/tag_set'

module PhotoFS
  module CLI
    class TagCommand < Command
      def self.matcher
        /tag [^\/\0]+ (\/)?([^\/\0]+(\/)?)+/
      end

      def self.usage
        'tag TAG IMAGE_PATH'
      end

      def initialize(args)
        @args_tag_name = args[1]
        @args_image_path = args[2]

        @images = PhotoFS::Data::ImageSet.new
        @tags = PhotoFS::Data::TagSet.new

        super args
      end

      def execute
        unless file_system.exist?(@args_image_path) && file_system.realpath(@args_image_path)
          raise Errno::ENOENT, @args_image_path
        end

        @real_image_path = file_system.realpath @args_image_path

        set_data_path @real_image_path

        initialize_database

        data_lock { tag_image }
      end

      private

      def tag_image # within lock
        image = @images.find_by_path @real_image_path

        if image
          tag = @tags.find_by_name(@args_tag_name) || @tags.add?(PhotoFS::Core::Tag.new @args_tag_name)

          tag.add image

          save
        else
          raise CommandException, "#{@real_image_path} is not a registered image under #{PhotoFS::FS.data_path}"
        end
      end

      def save
        @images.save!
        @tags.save!

        increment_database_write_counter # within the lock
      end

      Command.register_command self
    end
  end
end
