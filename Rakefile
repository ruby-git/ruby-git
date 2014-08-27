require 'git/version'
require 'rubygems'

task :default => :test

desc 'Run Unit Tests'
task :test do
  sh 'git config --global user.email "git@example.com"' if `git config user.email`.empty?
  sh 'git config --global user.name "GitExample"' if `git config user.name`.empty?

  $VERBOSE = true

  require File.dirname(__FILE__) + '/tests/all_tests.rb'
end
