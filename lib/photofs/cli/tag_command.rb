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

      def execute
        @real_image_path = valid_path @args_image_path

        initialize_datastore @real_image_path

        tag_image
      end

      private

      def tag_image
        PhotoFS::Data::Synchronize.read_write_lock.grab do |lock|
          image = @images.find_by_path @real_image_path

          if image
            tag = @tags.find_by_name(@args_tag_name) || @tags.add?(PhotoFS::Core::Tag.new @args_tag_name)

            tag.add image

            save

            lock.increment_count
          else
            raise CommandException, "#{@real_image_path} is not a registered image under #{PhotoFS::FS.data_path}"
          end
        end # lock
      end

      def save
        @images.save!
        @tags.save!
      end

      Command.register_command self
    end
  end
end
