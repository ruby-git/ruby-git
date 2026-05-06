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
  # On JRuby, override the default Fuubar formatter with 'documentation' so that
  # each test name is printed before it runs. This makes CI logs useful when the
  # suite hangs: the last printed test is the one that caused the hang.
  t.rspec_opts = '--format documentation' if RUBY_ENGINE == 'jruby'
end

# Run all specs in parallel
desc 'Run all specs in parallel'
task 'spec:parallel' do
  sh 'bundle exec parallel_rspec spec/'
end

# Run only unit specs in parallel
desc 'Run unit specs in parallel'
task 'spec:unit:parallel' do
  sh 'bundle exec parallel_rspec spec/unit/'
end

# Run only integration specs in parallel
desc 'Run integration specs in parallel'
task 'spec:integration:parallel' do
  sh 'bundle exec parallel_rspec spec/integration/'
end

CLEAN << 'coverage'
CLEAN << '.rspec_status'
CLEAN << 'rspec-report.xml'
