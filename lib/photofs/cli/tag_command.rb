require 'photofs/cli/command'
require 'photofs/cli/command_validators'
require 'photofs/core/tag'
require 'photofs/data/image_set'
require 'photofs/data/tag_set'

module PhotoFS
  module CLI
    class TagCommand < Command
      extend Command::MatcherTemplates
      include CommandValidators

      def self.matcher
        @@_matcher ||= Parser.new([Parser::Pattern.new(['tag', {:tags => match_tag_list}, {:paths => match_path}], :expand_tail => true)])
      end

      def self.usage
        ['tag TAG_LIST PATH [PATH_2] [PATH_N] where TAG_LIST is a space-separated list (wrap in quotes if listing more than one)']
      end

      def after_initialize(args)
        @args_tag_names = parsed_args[:tags].split.map { |tag| tag.strip }
        @args_image_paths = parsed_args[:paths]

        @images = PhotoFS::Data::ImageSet.new
        @tags = PhotoFS::Data::TagSet.new        
      end

      def datastore_start_path
        @real_image_paths.first
      end

      def modify_datastore
        images = valid_images_from_paths @images, @real_image_paths

        @args_tag_names.each do |tag_name|
          tag = @tags.find_by_name(tag_name) || @tags.add?(PhotoFS::Core::Tag.new tag_name)

          images.each { |image| tag.add image }
        end

        @images.save!
        @tags.save!

        return true
      end

      def validate
        @real_image_paths = @args_image_paths.map { |path| valid_path path }
      end

      private

      def invalid_images_error_message(missing_paths)
        "Images not imported: \n" + missing_paths.join("\n") + "\nImport all images first. No images were tagged."
      end

      Command.register_command self
    end
  end
end
