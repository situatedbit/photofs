require 'photofs/cli/command'
require 'photofs/core/tag'
require 'photofs/data/image_set'
require 'photofs/data/tag_set'

module PhotoFS
  module CLI
    class RetagCommand < Command
      extend Command::MatcherTemplates

      def self.matcher
        @@_matcher ||= Parser.new([Parser::Pattern.new(['retag', {:old_tag => match_tag}, {:new_tag => match_tag}, {:paths => match_path}], :expand_tail => true)])
      end

      def self.usage
        ['retag OLD_TAG NEW_TAG PATH [PATH_2] [PATH_N]']
      end

      def after_initialize(args)
        @args_old_tag_name = parsed_args[:old_tag]
        @args_new_tag_name = parsed_args[:new_tag]
        @args_image_paths = parsed_args[:paths]

        @images = PhotoFS::Data::ImageSet.new
        @tags = PhotoFS::Data::TagSet.new
      end

      def datastore_start_path
        @real_image_paths.first
      end

      def modify_datastore
        images = images_from_paths(@images, @real_image_paths)

        untag_old_tag(images)

        apply_new_tag(images)

        @images.save!
        @tags.save!

        return true
      end

      def validate
        @real_image_paths = @args_image_paths.map { |path| valid_path path }
      end

      private

      def apply_new_tag(images)
        new_tag = @tags.find_by_name(@args_new_tag_name) || @tags.add?(PhotoFS::Core::Tag.new @args_new_tag_name)

        images.each do |image|
          new_tag.add image
        end
      end

      def error_message(missing_paths)
        "Images not imported: \n" + missing_paths.join("\n") + "\nImport all images first. No images were tagged or untagged."
      end

      def images_from_paths(image_set, paths)
        image_path_pairs = image_set.find_by_paths(paths)

        non_imported_paths = image_path_pairs.keys.select { |path| image_path_pairs[path].nil? }

        raise(CommandException, error_message(non_imported_paths)) unless non_imported_paths.empty?

        image_path_pairs.values
      end

      def untag_old_tag(images)
        old_tag = @tags.find_by_name @args_old_tag_name

        old_tag.remove(images) if old_tag
      end

      Command.register_command self
    end
  end
end
