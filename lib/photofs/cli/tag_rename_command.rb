require 'photofs/cli'
require 'photofs/cli/command'
require 'photofs/data/tag_set'
require 'photofs/core/tag'

module PhotoFS
  module CLI
    class TagRenameCommand < Command
      extend Command::MatcherTemplates

      def self.matcher
        /\Arename tag #{match_tag} #{match_tag}\z/
      end

      def self.usage
        'rename tag OLD_TAG NEW_TAG'
      end

      def after_initialize(args)
        @from_tag_name = args[2]
        @to_tag_name = args[3]

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
