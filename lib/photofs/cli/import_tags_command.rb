require 'photofs/cli'
require 'photofs/cli/command'
require 'photofs/cli/command_validators'
require 'photofs/cli/data_utilities'
require 'photofs/cli/tag_json_parser'
require 'photofs/fs'

module PhotoFS
  module CLI
    class ImportTagsCommand < Command
      extend Command::MatcherTemplates
      include CommandValidators
      include DataUtilities

      def self.matcher
        @@_matcher ||= Parser.new [Parser::Pattern.new(['import', 'tags', {json_file: match_path}])]
      end

      def self.usage
        ['import tags TAGS_EXPORT_FILE']
      end

      def after_initialize(args)
        @json_file = parsed_args[:json_file]

        @images = PhotoFS::Data::ImageSet.new
        @tags = PhotoFS::Data::TagSet.new
        @parser = TagJsonParser.new
      end

      def datastore_start_path
        PhotoFS::FS.file_system.pwd
      end

      def modify_datastore
        # This will only apply tag bindings to images in the repository
        # It will not import new images, nor will it fail on tags bound to images
        # not in the repository. If a tag is not applied to any images, it will still
        # be created. If it is applied only to images missing from the repository, it
        # will still be created.
        tagged_output = []
        untagged_output = []

        @tags_to_import.each do |tag|
          tag_images @tags, tag.name, tag.images

          # Tagged images are the intersection of the imported tag's images and
          # the images already in the database (@images)
          tagged_images = (@images & tag).images.to_a
          untagged_images = tag.images - tagged_images

          tagged_output += tagged_images.map { |i| "  #{tag.name} ∋ #{i.path}" }
          untagged_output += untagged_images.map { |i| "  #{tag.name} ∌ #{i.path}" }
        end

        @output += ['Tagged:', tagged_output].flatten if !tagged_output.empty?
        @output += ['Missing from repository and not tagged:', untagged_output].flatten if !untagged_output.empty?

        @tags.save! unless @tags_to_import.empty?

        !@tags_to_import.empty?
      end

      def validate
        fs = PhotoFS::FS.file_system

        raise(CommandValidationException, "#{@json_file} is not a file") unless fs.exist?(@json_file) && !fs.directory?(@json_file)

        begin
          @tags_to_import = @parser.parse fs.read_file @json_file
        rescue => e
          raise(CommandValidationException, "Unable to import tags: #{e.message}")
        end
      end

      Command.register_command self
    end
  end
end
