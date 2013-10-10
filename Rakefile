require 'yard'
require 'yard/rake/yardoc_task'

require 'rspec/core/rake_task'

$log_dir = ENV['RASP_LOG']
$log_dir = "/dev/null" if $log_dir.nil? or $log_dir.size == 0

$clients = ENV['RASP_CLIENTS']
$clients = "scheduler" if $clients.nil? or $clients.size == 0

$server_port = ENV['RASP_PORT']
$server_port = "3000" if $server_port.nil? or $server_port.size == 0

# Import subtasks
Dir.glob(File.expand_path('../tasks/*.rake', __FILE__)).each do |f|
    import(f)
end

desc 'Default: show config.'
task :default => "config:show"

desc "Starts the whole stuff"
task :start => [ 'utils:clearfb', 'server:start', 'clients:analog_sensors:start' ]

desc "Stops the whole stuff"
multitask :stop => [ 'server:stop', 'clients:analog_sensors:stop' ]

namespace :spec do
  desc "Run specs"
  RSpec::Core::RakeTask.new do |t|
    t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
    # Put spec opts in a file named .rspec in root
  end

  desc "Generate code coverage"
  RSpec::Core::RakeTask.new(:coverage) do |t|
    t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
    ENV['COVERAGE'] = 'true'
  end
end

namespace :doc do
  desc "Generates doc"
  YARD::Rake::YardocTask.new do |t|
    t.files   = ['lib/**/*.rb', '-', 'README.md' ]   # add other paths in array if required
    # the dash '-' is required so Yard knows it is NOT code
  end
end
