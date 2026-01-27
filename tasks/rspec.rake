# frozen_string_literal: true

require 'rspec/core/rake_task'

# Run all specs
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/**/*_spec.rb'
end

# Run only unit specs (mocked, fast)
RSpec::Core::RakeTask.new('spec:unit') do |t|
  t.pattern = 'spec/unit/**/*_spec.rb'
end

# Run only integration specs (real git, slower)
RSpec::Core::RakeTask.new('spec:integration') do |t|
  t.pattern = 'spec/integration/**/*_spec.rb'
end

CLEAN << 'coverage'
CLEAN << '.rspec_status'
CLEAN << 'rspec-report.xml'
