# frozen_string_literal: true

require_relative 'support/installed_gem_check'

desc 'Build the git gem, install it into an empty gem home, and run a sanity check'
task 'test:gem' do
  output = InstalledGemCheck.run('git.gemspec', <<~RUBY)
    require 'git'
    puts Git.open('.').log.execute.size
  RUBY
  raise "Expected gem test to return an integer, got: #{output.inspect}" unless output.chomp.match?(/\A\d+\z/)

  puts 'Gem Test Succeeded'
end
