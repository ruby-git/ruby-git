require 'bundler/gem_tasks'
require 'English'

require "#{File.expand_path(File.dirname(__FILE__))}/lib/git/version"

default_tasks = []

desc 'Run Unit Tests'
task :test do
  sh 'git config --global user.email "git@example.com"' if `git config user.email`.empty?
  sh 'git config --global user.name "GitExample"' if `git config user.name`.empty?

  require File.dirname(__FILE__) + '/tests/all_tests.rb'
end
default_tasks << :test

unless RUBY_PLATFORM == 'java'
  #
  # YARD documentation for this project can NOT be built with JRuby.
  # This project uses the redcarpet gem which can not be installed on JRuby.
  #
  require 'yard'
  YARD::Rake::YardocTask.new
  CLEAN << '.yardoc'
  CLEAN << 'doc'
  default_tasks << :yard

  require 'yardstick/rake/verify'
  Yardstick::Rake::Verify.new(:'yardstick:coverage') do |t|
    t.threshold = 50
    t.require_exact_threshold = false
  end
  default_tasks << :'yardstick:coverage'

  desc 'Run yardstick to check yard docs'
  task :yardstick do
    sh "yardstick 'lib/**/*.rb'"
  end
  # Do not include yardstick as a default task for now since there are too many
  # warnings.  Will work to get the warnings down before re-enabling it.
  #
  # default_tasks << :yardstick
end

if RUBY_PLATFORM == 'java' && Gem.win_platform?
  # Reimplement the :build and :install task for JRuby on Windows
  # There is a bug in JRuby on Windows that makes the `build` task from `bundler/gem_tasks` fail.
  # Once https://github.com/jruby/jruby/issues/6516 is fixed, this block can be deleted.
  version = Git::VERSION
  pkg_name = 'git'
  gem_file = "pkg/#{pkg_name}-#{version}.gem"

  Rake::Task[:build].clear
  task :build do
    FileUtils.mkdir 'pkg' unless File.exist? 'pkg'
    `gem build #{pkg_name}.gemspec --output "#{gem_file}" --quiet`
    raise 'Gem build failed' unless $CHILD_STATUS.success?
    puts "#{pkg_name} #{version} built to #{gem_file}."
  end

  Rake::Task[:install].clear
  task :install => :build do
    `gem install #{gem_file} --quiet`
    raise 'Gem install failed' unless $CHILD_STATUS.success?
    puts "#{pkg_name} (#{version}) installed."
  end

  CLOBBER << gem_file
end

default_tasks << :build

task default: default_tasks

desc 'Build and install the git gem and run a sanity check'
task :'test:gem' => :install do
  output = `ruby -e "require 'git'; g = Git.open('.'); puts g.log.size"`.chomp
  raise 'Gem test failed' unless $CHILD_STATUS.success?
  raise 'Expected gem test to return an integer' unless output =~ /^\d+$/

  puts 'Gem Test Succeeded'
end
