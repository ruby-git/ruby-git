require 'rdoc/task'
require 'rubygems'

require "#{File.expand_path(File.dirname(__FILE__))}/lib/git/version"

desc "Upload Docs"
task :upload_docs do |t|
 system('rsync -rv --delete doc/ git.rubyforge.org:/var/www/gforge-projects/git')
end

desc "Run Unit Tests"
task :test do |t|
    $VERBOSE = true
    require File.dirname(__FILE__) + '/tests/all_tests.rb'
end

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "ruby-git #{Git::VERSION}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

