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
#
# Matches are filtered to dir so that each task only ever runs the specs it owns,
# no matter how broad SPEC is. This keeps every task self-consistent (a unit spec
# can never be run by spec:integration under integration's runner and env) and lets
# a single cross-layer glob drive `rake spec`, e.g.
# `SPEC=spec/**/git/commands/add_spec.rb rake spec` runs the unit file under
# spec:unit and the integration file under spec:integration. A SPEC that matches
# files elsewhere in spec/ but none under dir yields no targets, and the caller
# skips the task rather than falling back to running all of dir.
def spec_targets(dir)
  spec_files = ENV.fetch('SPEC', nil)&.strip
  return [dir] if spec_files.nil? || spec_files.empty?

  targets = FileList[spec_files].sort
  raise "SPEC=#{spec_files.inspect} did not match any files" if targets.empty?

  targets.select { |target| target.delete_prefix('./').start_with?(dir) }
end

# True when targets name exactly one spec file (as opposed to a directory, or
# several files).
def single_spec_file?(targets)
  targets.one? && File.file?(targets.first)
end

# The runner for targets: parallel_rspec only when the task runs in parallel and
# there is more than one spec file to spread across workers.
#
# A single file always uses plain rspec. Worker startup is pure overhead with nothing
# to divide, and parallel_tests sets TEST_ENV_NUMBER in every worker, which makes
# spec_helper fall back from the documentation formatter to plain dots -- the opposite
# of what a run narrowed to one file wants.
def spec_runner(targets, parallel:)
  parallel && !single_spec_file?(targets) ? 'parallel_rspec' : 'rspec'
end

# Run the SPEC-filtered targets for dir, or announce a skip when SPEC selected nothing
# under dir. Silently doing nothing would read as a passing run of the whole directory.
def run_spec_task(name, dir, env, parallel:)
  targets = spec_targets(dir)

  if targets.empty?
    puts "Skipping #{name}: SPEC=#{ENV.fetch('SPEC', nil)} matched no files under #{dir}"
  else
    sh env, 'bundle', 'exec', spec_runner(targets, parallel: parallel), *targets
  end
end

def define_parallel_spec_task(name, dir, env: {})
  task name do
    run_spec_task(name, dir, env, parallel: true)
  end
end

def define_serial_spec_task(name, dir, env: {})
  task name do
    run_spec_task(name, dir, env, parallel: false)
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
desc 'Run unit and integration RSpec tests (SPEC=<glob> to run specific files)'
task spec: %w[spec:unit spec:integration]

CLEAN << 'coverage'
CLEAN << '.rspec_status'
CLEAN << 'rspec-report.xml'
