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

desc 'Run all tests (TestUnit and RSpec)'
task test_all: %i[test spec]
