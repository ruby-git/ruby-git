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

  # yard:lint

  # Lints YARD documentation against the project's standards and enforces the
  # minimum documentation coverage threshold. Configuration lives in
  # .yard-lint.yml; legacy offenses are baselined in .yard-lint-todo.yml.
  #
  desc 'Lint YARD documentation with yard-lint'
  task :'yard:lint' do
    sh 'bundle exec yard-lint lib/'
  end

  # yard:example-test

  require 'yard_example_test/rake'

  YardExampleTest::RakeTask.new('yard:example-test') do |task|
    task.pattern = 'lib/git/commands/arguments.rb'
  end

  # yard

  desc 'Run YARD documentation tasks (build, lint, example-test)'
  task yard: %i[yard:build yard:lint yard:example-test]
end
