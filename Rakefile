APP_RAKEFILE = File.expand_path("../test/dummy/Rakefile", __FILE__)

load 'rails/tasks/engine.rake'
load 'rails/tasks/statistics.rake'

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec
