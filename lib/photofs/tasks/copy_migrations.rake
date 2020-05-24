require 'fileutils'

namespace :photofs do
  desc 'Copy migrations to the local application db/migrate directory'
  task copy_migrations: :environment do
    migrations_source_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'db', 'migrate'))

    migrations = Dir.chdir migrations_source_path do
      Dir['*.rb'].map { |file| File.join migrations_source_path, file }
    end

    puts "Copying migrations to db/migrate..."

    migrations_dest_path = File.join(File.expand_path(Dir.pwd), 'db', 'migrate')

    FileUtils.mkdir_p(migrations_dest_path, verbose: true)

    migrations.each do |migration|
      puts ""
      FileUtils.cp(migration, migrations_dest_path, verbose: true)
    end
  end
end
