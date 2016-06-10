require 'photofs/cli'
require 'photofs/cli/command'
require 'photofs/cli/command_validators'
require 'photofs/data/tag_set'
require 'photofs/core/tag'

module PhotoFS
  module CLI
    class TagRenameCommand < Command
      extend Command::MatcherTemplates
      include CommandValidators

      def self.matcher
        @@_matcher ||= Parser.new([Parser::Pattern.new(['rename', 'tag', {:from_tag_name => match_tag}, {:to_tag_name => match_tag}])])
      end

      def self.usage
        ['rename tag OLD_TAG NEW_TAG']
      end

      def after_initialize(args)
        @from_tag_name = parsed_args[:from_tag_name]
        @to_tag_name = parsed_args[:to_tag_name]

        @tags = PhotoFS::Data::TagSet.new
      end

      def datastore_start_path
        Dir.getwd
      end

      def modify_datastore
        from_tag = @tags.find_by_name @from_tag_name

        raise(Command::CommandException, "#{@from_tag_name}: tag does not exist") unless from_tag

        raise(Command::CommandException, "#{@to_tag_name}: tag already exists") if @tags.find_by_name(@to_tag_name)

        @tags.rename from_tag, PhotoFS::Core::Tag.new(@to_tag_name)

        @tags.save!

        return true
      end

      Command.register_command self
    end
  end
end
