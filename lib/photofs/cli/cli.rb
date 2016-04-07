require 'photofs/cli/command'
require 'photofs/cli/bad_command'

module PhotoFS
  module CLI
    def self.parse(args)
      matcher = @@commands.keys.select { |pattern| !pattern.match(args.join(' ')).nil? }.first

      if matcher
        @@commands[matcher].new args
      else
        print_usage

        BadCommand.new args
      end
    end

    def self.register_command(command)
      @@commands ||= {}

      @@commands[command.matcher] = command 

      @@usages ||= []

      @@usages << command.usage
    end

    def self.print_usage
      puts "usage: \n"
      @@usages.each { |usage| puts "  #{usage}\n" }
    end
  end
end
