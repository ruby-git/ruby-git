# frozen_string_literal: true

require 'English'

desc 'Build and install the git gem and run a sanity check'
task 'test:gem': :install do
  output = `ruby -e "require 'git'; g = Git.open('.'); puts g.log.size"`.chomp
  raise 'Gem test failed' unless $CHILD_STATUS.success?
  raise 'Expected gem test to return an integer' unless output =~ /^\d+$/

  puts 'Gem Test Succeeded'
end
