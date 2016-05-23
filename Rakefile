require "bundler/gem_tasks"
require 'rawgento_models'

require 'rake/testtask'

task :default => :spec

RawgentoModels.load_tasks
# These tasks should be solveable either via a rake task or via single executables

# initial load

# remote scrape

# local load and update

# stock update

Rake::TestTask.new do |t|
  t.pattern = "test/*test.rb"
end
#Rake::TestTask.new do |t|
#  t.libs << "test"
#  t.test_files = FileList['test/*test.rb']
#  t.verbose = true
#end
