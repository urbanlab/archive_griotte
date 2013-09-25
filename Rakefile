require 'yard'
require 'yard/rake/yardoc_task'

require 'rspec/core/rake_task'

desc 'Default: run specs.'
task :default => "spec:spec"

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
