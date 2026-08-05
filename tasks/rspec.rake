# frozen_string_literal: true

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

# SPEC lets a developer target one or more specific files, e.g.
# `SPEC=spec/unit/git/version_spec.rb rake spec:unit`, running just those files
# instead of the whole directory. Both rspec and parallel_rspec recurse a bare
# directory argument using their own default *_spec.rb pattern, so no explicit
# --pattern flag is needed for the non-SPEC case.
def spec_targets(dir)
  spec_files = ENV.fetch('SPEC', nil)&.strip
  return [dir] if spec_files.nil? || spec_files.empty?

  targets = FileList[spec_files].sort
  raise "SPEC=#{spec_files.inspect} did not match any files" if targets.empty?

  targets
end

def define_parallel_spec_task(name, dir, env: {})
  task name do
    sh env, 'bundle', 'exec', 'parallel_rspec', *spec_targets(dir)
  end
end

def define_serial_spec_task(name, dir, env: {})
  task name do
    sh env, 'bundle', 'exec', 'rspec', *spec_targets(dir)
  end
end

# Define a spec task that runs in parallel (via parallel_tests) when parallel_tests? is
# true, and serially (via a direct `bundle exec rspec` call) otherwise. env, when given,
# is passed to `sh` and scoped to just the spawned test subprocess(es).
def define_spec_task(name, dir, desc_text, env: {})
  desc desc_text
  parallel_tests? ? define_parallel_spec_task(name, dir, env: env) : define_serial_spec_task(name, dir, env: env)
end

# Run only unit specs. These run in a few seconds, so parallel_tests startup
# overhead isn't worth it - always run serially.
desc 'Run unit RSpec tests (mocked, fast; SPEC=<glob> to run specific files)'
define_serial_spec_task('spec:unit', 'spec/unit/')

# Run only integration specs. Coverage is forced off (regardless of the COVERAGE
# env var): integration tests intentionally aren't exhaustive, so tracking or
# reporting coverage for them would misleadingly suggest that low integration
# coverage is a problem to fix.
define_spec_task(
  'spec:integration', 'spec/integration/',
  'Run integration RSpec tests (real git, slower; SPEC=<glob> to run specific files)',
  env: { 'COVERAGE' => 'false' }
)

# Run all specs, keeping unit and integration output clearly separated
desc 'Run unit and integration RSpec tests'
task spec: %w[spec:unit spec:integration]

CLEAN << 'coverage'
CLEAN << '.rspec_status'
CLEAN << 'rspec-report.xml'
