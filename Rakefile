require 'bundler/gem_tasks'
require 'rubygems'

require "#{File.expand_path(File.dirname(__FILE__))}/lib/git/version"

task :default => :test

require 'yard'
YARD::Rake::YardocTask.new
CLEAN << '.yardoc'
CLEAN << 'doc'

require 'yardstick/rake/verify'
Yardstick::Rake::Verify.new do |verify|
  verify.threshold = 100
end

desc 'Run yardstick to check yard docs'
task :yardstick do
  sh "yardstick 'lib/**/*.rb'"
end

desc 'Run Unit Tests'
task :test do |t|
  sh 'git config --global user.email "git@example.com"' if `git config user.email`.empty?
  sh 'git config --global user.name "GitExample"' if `git config user.name`.empty?

  $VERBOSE = true

  require File.dirname(__FILE__) + '/tests/all_tests.rb'
end
