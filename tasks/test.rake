# frozen_string_literal: true

desc 'Run Unit Tests (TestUnit)'
task :test do
  sh 'ruby bin/test'

  # You can run individual test files (or multiple files) from the command
  # line with:
  #
  # $ bin/test test_archive.rb
  #
  # $ bin/test test_archive.rb test_object.rb
end

desc 'Run Test::Unit tests in parallel'
task 'test:parallel' do
  # Ensure git global config is set (normally done by bin/test for serial runs).
  # CI runners may not have a git identity configured.
  sh 'git config --global user.email "git@example.com"' if `git config --global user.email`.empty?
  sh 'git config --global user.name "GitExample"' if `git config --global user.name`.empty?
  sh 'git config --global init.defaultBranch main' if `git config --global init.defaultBranch`.empty?

  sh({ 'PARALLEL_TESTS_EXECUTABLE' => 'ruby -Itests' },
     "bundle exec parallel_test tests/units/ --suffix 'test_.+\\.rb$'")
end
