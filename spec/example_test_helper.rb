# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'git'

Arguments = Git::Commands::Arguments

# Load RSpec matchers so that we can use them in the examples
require 'rspec/expectations'
require 'rspec/matchers'

YardExampleTest::Example.include RSpec::Matchers
