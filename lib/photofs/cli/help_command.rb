require 'photofs/cli'
require 'photofs/cli/command'

module PhotoFS
  module CLI
    class HelpCommand < Command
      def self.matcher
        @@_matcher ||= Parser.new([Parser::Pattern.new(['help|usage'])])
      end

      def self.usage
        ["help", "usage"]
      end

      def execute
        puts "usage: \n"
        self.class.command_usages.sort.each { |usage| puts "  #{usage}\n" }
      end

      Command.register_command self
    end
  end
end
