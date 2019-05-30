# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rubygems'

require "#{__dir__}/lib/git/version"

require 'rubocop/rake_task'

require 'rake/testtask'

task default: %w[test rubocop]

desc 'Run Unit Tests'
Rake::TestTask.new do |t|
  sh 'git config --global user.email "git@example.com"' if `git config user.email`.empty?
  sh 'git config --global user.name "GitExample"' if `git config user.name`.empty?

  t.libs << 'tests'

  t.test_files = FileList['tests/units/test*.rb']

  t.verbose = true
end

RuboCop::RakeTask.new
