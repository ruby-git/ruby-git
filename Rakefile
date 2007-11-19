require 'rubygems'
Gem::manage_gems
require 'rake/gempackagetask'

spec = Gem::Specification.new do |s|
    s.platform  =   Gem::Platform::RUBY
    s.name      =   "git"
    s.version   =   "1.0.4"
    s.author    =   "Scott Chacon"
    s.email     =   "schacon@gmail.com"
    s.summary   =   "A package for using Git in Ruby code."
    s.files     =   FileList['lib/**/*', 'tests/**/*', 'doc/**/*'].to_a
    s.require_path  =   "lib"
    s.autorequire   =   "git"
    s.test_files = Dir.glob('tests/*.rb')
    s.has_rdoc  =   true
    s.extra_rdoc_files  =   ["README"]
end

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
    require File.dirname(__FILE__) + '/tests/all_tests.rb'
end

