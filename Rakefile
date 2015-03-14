require 'rubygems'

require "#{File.expand_path(File.dirname(__FILE__))}/lib/git/version"

task :default => :test

desc 'Run Unit Tests'
task :test do |t|
  sh 'git config --global user.email "git@example.com"' if `git config user.email`.empty?
  sh 'git config --global user.name "GitExample"' if `git config user.name`.empty?

  $VERBOSE = true

  require File.dirname(__FILE__) + '/tests/all_tests.rb'
end


