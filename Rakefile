# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rubygems'

require "#{__dir__}/lib/git/version"

require 'rubocop/rake_task'

task default: %w[test rubocop]

desc 'Run Unit Tests'
task :test do |_t|
  sh 'git config --global user.email "git@example.com"' if `git config user.email`.empty?
  sh 'git config --global user.name "GitExample"' if `git config user.name`.empty?

  $VERBOSE = true

  require File.dirname(__FILE__) + '/tests/all_tests.rb'
end

RuboCop::RakeTask.new
