require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new :spec
RuboCop::RakeTask.new

desc 'Run tests and linter'
task default: %i[spec rubocop]

desc 'Alias of default: spec linter'
task test: %i[spec rubocop]
