# frozen_string_literal: true

begin
  require 'yard-doctest'
  require 'yard/doctest/rake'

  desc 'Run YARD doctest to verify documentation examples'
  YARD::Doctest::RakeTask.new do |task|
    task.pattern = 'lib/git/commands/arguments.rb'
  end
rescue LoadError
  # yard-doctest not available (e.g., JRuby)
end
