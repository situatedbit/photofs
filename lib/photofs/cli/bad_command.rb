require 'photofs/cli/command'

module PhotoFS
  module CLI
    class BadCommand < Command
      def initialize(usages, args)
        @usages = usages
        @bad_command = args[0]

        super args
      end

      def execute
        puts "'#{@bad_command}' is not a valid command\n\n"
        puts "usage: \n"
        @usages.each { |usage| puts "  #{usage}\n" }
      end

    end
  end
end
