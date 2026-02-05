# frozen_string_literal: true

# YARD documentation for this project can NOT be built with JRuby or TruffleRuby.
# This project uses the redcarpet gem which can not be installed on JRuby.
#
unless RUBY_PLATFORM == 'java' || RUBY_ENGINE == 'truffleruby'
  # yard:build

  require 'yard'

  YARD::Rake::YardocTask.new('yard:build') do |t|
    t.files = %w[lib/**/*.rb]
    t.stats_options = ['--list-undoc']
  end

  CLEAN << '.yardoc'
  CLEAN << 'doc'

  # yard:audit

  desc 'Run yardstick to show missing YARD doc elements'
  task :'yard:audit' do
    sh "yardstick 'lib/**/*.rb'"
  end

  # yard:coverage

  require 'yardstick/rake/verify'

  Yardstick::Rake::Verify.new(:'yard:coverage') do |verify|
    verify.threshold = 75
    verify.require_exact_threshold = false
  end

  # yard:doctest

  require 'yard-doctest'
  require 'yard/doctest/rake'

  desc 'Run YARD doctest to verify documentation examples'
  YARD::Doctest::RakeTask.new('yard:doctest') do |task|
    task.pattern = 'lib/git/commands/arguments.rb'
  end

  # yard

  # Do not include yard:audit in the yard task because there are too many
  # missing YARD doc elements
  #
  desc 'Run YARD documentation tasks (build, coverage, doctest)'
  task yard: %i[yard:build yard:coverage yard:doctest]
end
