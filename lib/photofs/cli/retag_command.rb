require 'photofs/cli/command'
require 'photofs/cli/command_validators'
require 'photofs/cli/data_utilities'
require 'photofs/core/tag'
require 'photofs/data/image_set'
require 'photofs/data/tag_set'
require 'photofs/fs/normalized_path'

module PhotoFS
  module CLI
    class RetagCommand < Command
      extend Command::MatcherTemplates
      include CommandValidators
      include DataUtilities

      def self.matcher
        @@_matcher ||= Parser.new([Parser::Pattern.new(['retag', {old_tags: match_tag_list}, {new_tags: match_tag_list}, {paths:  match_path}], expand_tail:  true)])
      end

      def self.usage
        ['retag OLD_TAG_LIST NEW_TAG_LIST PATH [PATH_2] [PATH_N], where tag lists are space-separated']
      end

      def after_initialize(args)
        @args_old_tag_names = parsed_args[:old_tags].split.map { |tag| tag.strip }
        @args_new_tag_names = parsed_args[:new_tags].split.map { |tag| tag.strip }
        @args_image_paths = parsed_args[:paths]

        @images = PhotoFS::Data::ImageSet.new
        @tags = PhotoFS::Data::TagSet.new
      end

      def datastore_start_path
        @real_image_paths.first
      end

      def modify_datastore
        images = valid_images_from_paths @images, normalized_image_paths(@real_image_paths)

        @args_old_tag_names.each do |tag_name|
          untag_images @tags, tag_name, images

          @output += images.map { |i| "#{tag_name} ∉ #{i.path}" }
        end

        @args_new_tag_names.each do |tag_name|
          tag_images @tags, tag_name, images

          @output += images.map { |i| "#{tag_name} ∈ #{i.path}" }
        end

        @tags.save!

        return true
      end

      def validate
        @real_image_paths = @args_image_paths.map { |path| valid_path path }
      end

      private

      def invalid_images_error_message(missing_paths)
        "Images not imported: \n" + missing_paths.join("\n") + "\nImport all images first. No images were tagged or untagged."
      end

      Command.register_command self
    end
  end
end
