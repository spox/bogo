require "bundler/setup"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = "test/specs/**/*_spec.rb"
end

task :default => [] do
  Rake::Task[:spec].invoke
end
