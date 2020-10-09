require 'json'
require 'photofs/cli'
require 'photofs/cli/command'
require 'photofs/data/tag_set'
require 'photofs/fs'

module PhotoFS
  module CLI
    # returns JSON-formatted tags collection for the entire repository
    class ExportTagsCommand < Command
      extend Command::MatcherTemplates

      def self.matcher
        @@_matcher ||= Parser.new [Parser::Pattern.new(['export', 'tags'])]
      end

      def self.usage
        ['export tags']
      end

      def datastore_start_path
        PhotoFS::FS.file_system.pwd
      end

      def modify_datastore
        tag_hashes = PhotoFS::Data::TagSet.new.map do |tag|
          { name: tag.name, paths: tag.images.map { |i| i.path } }
        end

        @output << JSON.generate({ tags: tag_hashes })
      end

      Command.register_command self
    end
  end
end
