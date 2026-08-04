# frozen_string_literal: true

require 'rspec/core/rake_task'

# Skip parallel test execution when the PARALLEL_TESTS environment variable is set to a falsy value
def parallel_tests_disabled_via_env?
  parallel_tests_env = ENV.fetch('PARALLEL_TESTS', 'true').strip.downcase
  %w[false 0 no off].include?(parallel_tests_env)
end

# Use parallel test execution for MRI where it cuts build times by 30-48%.
# JRuby and TruffleRuby are slower with parallel_tests because each worker
# process pays JVM/Truffle startup and warm-up overhead independently,
# resulting in 18-28% slower builds vs. serial execution.
def parallel_tests?
  RUBY_ENGINE == 'ruby' && !parallel_tests_disabled_via_env?
end

def define_parallel_spec_task(name, dir)
  task name do
    sh 'bundle', 'exec', 'parallel_rspec', dir
  end
end

def define_serial_spec_task(name, dir)
  RSpec::Core::RakeTask.new(name) do |t|
    t.pattern = "#{dir}**/*_spec.rb"
    # On JRuby, use 'documentation' formatter so each test name is printed before
    # it runs. When the suite hangs, the last printed line identifies the blocking
    # test.
    t.rspec_opts = '--format documentation' if RUBY_ENGINE == 'jruby'
  end
end

# Define a spec task that runs in parallel (via parallel_tests) when parallel_tests? is
# true, and serially (via RSpec::Core::RakeTask) otherwise.
def define_spec_task(name, dir, desc_text)
  desc desc_text
  parallel_tests? ? define_parallel_spec_task(name, dir) : define_serial_spec_task(name, dir)
end

# Run only unit specs. These run in a few seconds, so parallel_tests startup
# overhead isn't worth it - always run serially.
desc 'Run unit RSpec tests (mocked, fast)'
define_serial_spec_task('spec:unit', 'spec/unit/')

# Run only integration specs
define_spec_task('spec:integration', 'spec/integration/', 'Run integration RSpec tests (real git, slower)')

# Run all specs, keeping unit and integration output clearly separated
desc 'Run unit and integration RSpec tests'
task spec: %w[spec:unit spec:integration]

CLEAN << 'coverage'
CLEAN << '.rspec_status'
CLEAN << 'rspec-report.xml'
