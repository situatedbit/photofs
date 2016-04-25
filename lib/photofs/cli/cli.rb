require 'photofs/cli/command'

# explicitly include all commands so they can register
require 'photofs/cli/bad_command'
require 'photofs/cli/import_command'
require 'photofs/cli/tag_command'
require 'photofs/cli/tag_rename_command'

module PhotoFS
  module CLI
    def self.execute(args)
      begin
        parse(args).execute
      rescue PhotoFS::CLI::Command::CommandException => e
        puts "#{e.message}\n"
      end
    end

    def self.parse(args)
      commands = PhotoFS::CLI::Command.registered_commands

      matcher = commands.keys.select { |pattern| !pattern.match(args.join(' ')).nil? }.first

      if matcher
        commands[matcher].new args
      else
        BadCommand.new @PhotoFS::CLI::Command.command_usages, args
      end
    end
  end
end
