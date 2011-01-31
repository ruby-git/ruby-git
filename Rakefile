require 'rubygems'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "git"
    gem.summary = %Q{Ruby/Git is a Ruby library that can be used to create, read and manipulate Git repositories by wrapping system calls to the git binary}
    gem.email = "schacon@gmail.com"
    gem.homepage = "http://github.com/schacon/ruby-git"
    gem.authors = "Scott Chacon"
    gem.rubyforge_project = "git"
    gem.files = FileList["lib/**/*.rb"]
    gem.test_files = FileList["test/*.rb"]
    gem.extra_rdoc_files = ["README"]
    gem.requirements << 'git 1.6.0.0, or greater'
    
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end

  Jeweler::RubyforgeTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end


desc "Upload Docs"
task :upload_docs do |t|
 system('rsync -rv --delete doc/ git.rubyforge.org:/var/www/gforge-projects/git')
end

desc "Run Unit Tests"
task :test do |t|
    $VERBOSE = true
    require File.dirname(__FILE__) + '/tests/all_tests.rb'
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION.yml')
    config = YAML.load(File.read('VERSION.yml'))
    version = "#{config[:major]}.#{config[:minor]}.#{config[:patch]}"
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "ruby-git #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

