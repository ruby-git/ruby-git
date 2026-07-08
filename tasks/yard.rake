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
  # .yard-lint.yml.
  #
  # yard-lint requires Ruby >= 3.3, so the lint task is only defined and only
  # included in the aggregate `yard` task on Ruby 3.3+.
  #
  yard_lint_supported = Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.3.0')

  if yard_lint_supported
    desc 'Lint YARD documentation with yard-lint'
    task :'yard:lint' do
      sh 'bundle exec yard-lint lib/'
    end
  end

  # yard:example-test

  require 'yard_example_test/rake'

  YardExampleTest::RakeTask.new('yard:example-test') do |task|
    task.pattern = 'lib/git/commands/arguments.rb'
  end

  # yard

  yard_tasks = %i[yard:build]
  yard_tasks << :'yard:lint' if yard_lint_supported
  yard_tasks << :'yard:example-test'

  yard_steps = ['build']
  yard_steps << 'lint' if yard_lint_supported
  yard_steps << 'example-test'

  desc "Run YARD documentation tasks (#{yard_steps.join(', ')})"
  task yard: yard_tasks
end
