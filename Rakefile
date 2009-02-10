require 'rubygems'
Gem::manage_gems
require 'rake/gempackagetask'

spec = eval(File.read('ruby-git.gemspec'))

Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_tar = true
end

task :default => "pkg/#{spec.name}-#{spec.version}.gem" do
    puts "generated latest version"
end

desc "Regenerate Documentation"
task :doc do |t|
 system('rdoc lib/ README --main README --inline-source')
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

