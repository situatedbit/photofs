require 'photofs/cli/command'

# explicitly include all commands so they can register
require 'photofs/cli/bad_command'
require 'photofs/cli/export_tags_command'
require 'photofs/cli/help_command'
require 'photofs/cli/init_command'
require 'photofs/cli/import_images_command'
require 'photofs/cli/import_tags_command'
require 'photofs/cli/prune_command'
require 'photofs/cli/retag_command'
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

      command = commands.select { |command| command.match? args }.first

      if command
        command.new args
      else
        BadCommand.new PhotoFS::CLI::Command.command_usages, args
      end
    end
  end
end
