require 'bundler/gem_tasks'
require 'rake/testtask'

task default: :test

desc 'Run tests'
Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/*_test.rb'].exclude('test/redmine/**/*')
  t.verbose = true
end
