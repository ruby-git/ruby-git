# frozen_string_literal: true

# Force unbuffered output so that CI logs show progress even if the process hangs
# before a normal exit (Fuubar/ruby-progressbar buffers output in non-TTY mode).
$stdout.sync = true
$stderr.sync = true

# Load support files
Dir[File.join(__dir__, 'support', '**', '*.rb')].each { |f| require f }

# Configure RSpec
RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # Configure expectations
  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end

  # Use the documentation formatter for detailed output
  config.default_formatter = 'doc' if config.files_to_run.one?

  # Run specs in random order to surface order dependencies
  config.order = :random
  Kernel.srand config.seed

  # Configure mocking
  config.mock_with :rspec do |mocks|
    # Prevent mocking or stubbing of methods that don't exist
    mocks.verify_partial_doubles = true
  end

  # Automatically tag specs in spec/integration as :integration
  config.define_derived_metadata(file_path: %r{/spec/integration/}) do |metadata|
    metadata[:integration] = true
  end

  # Shared setup for all specs
  config.before(:each) do
    # Any global setup can go here
  end

  # Shared teardown for all specs
  config.after(:each) do
    # Any global teardown can go here
  end
end

# SimpleCov configuration
#
# JRuby and TruffleRuby do not provide reliable coverage data.
# SimpleCov's branch coverage crashes on TruffleRuby and coverage metrics
# are not meaningful on alternative runtimes. Skip coverage entirely.
#
SIMPLECOV_ENABLED = RUBY_ENGINE == 'ruby'

if SIMPLECOV_ENABLED
  require 'simplecov'
  require 'simplecov-lcov'
  require 'simplecov-rspec'
end

# Returns `false` when git meets the minimum version, or a skip message when it does not
#
# Pass the return value to RSpec's `skip:` metadata key to conditionally skip
# an example group when the installed git is too old to support the feature
# under test.
#
# @param minimum_version [String] the minimum git version required (e.g., `'2.43.0'`)
#
#   Shorter strings are treated as if trailing `.0` components were appended, so
#   `'2.43'` is equivalent to `'2.43.0'`.
#
# @param feature [String] the feature name to include in the skip reason
#
# @return [false, String] `false` if the installed git meets the minimum version;
#   otherwise a human-readable skip reason string
#
# @example
#   RSpec.describe MyFeature, skip: unless_git('2.43', 'git show-ref --exists') do
#     it 'works' do
#       # ...
#     end
#   end
#
def unless_git(minimum_version, feature)
  minimum_version_parts = minimum_version.split('.').map(&:to_i)
  minimum_version_parts.fill(0, minimum_version_parts.length...3)
  actual_version_parts = Git.git_version.to_a

  return false if (actual_version_parts <=> minimum_version_parts) >= 0

  actual_version = actual_version_parts.join('.')

  "#{feature} requires git #{minimum_version} or later; your git version is #{actual_version}"
end

def ci_build? = ENV.fetch('GITHUB_ACTIONS', 'false') == 'true'

# Returns false when running on CI, or a skip-reason string when not on CI.
# Use as the `skip:` metadata value for tests that modify shared OS state
# (e.g. launchctl/systemd scheduler entries) and must only run on CI where
# the environment is guaranteed clean.
#
# Example:
#   RSpec.describe MyClass, skip: unless_ci_build('reason') do ...
#
def unless_ci_build(feature)
  return false if ci_build?

  "#{feature} modifies OS-level state; only runs on CI (set GITHUB_ACTIONS=true to run locally)"
end

if SIMPLECOV_ENABLED
  if ci_build?
    SimpleCov.formatters = [
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::LcovFormatter
    ]
  end

  SimpleCov.enable_coverage :branch

  SimpleCov::RSpec.start(
    coverage_threshold: 100,
    fail_on_low_coverage: false,
    list_uncovered_lines: false
  ) do
    command_name "RSpec-#{ENV['TEST_ENV_NUMBER']}" if ENV['TEST_ENV_NUMBER']
  end
end

require 'git'

# Helper to create a mock CommandLineResult for use in specs
#
# @param stdout [String] the stdout to return
# @param stderr [String] the stderr to return (default: '')
# @param exitstatus [Integer] the exit status code (default: 0)
# @return [Git::CommandLineResult] a CommandLineResult object
def command_result(stdout = '', stderr: '', exitstatus: 0)
  status = double('status', success?: exitstatus.zero?, exitstatus: exitstatus, signaled?: false)
  Git::CommandLineResult.new(%w[git], status, stdout, stderr)
end

# Helper to expect a command call with raise_on_failure: false automatically included
#
# This helper simplifies testing commands that inherit from Commands::Base, which
# always passes raise_on_failure: false to the execution context.
#
# @param args [Array] the command arguments to expect
#
# @param execution_options [Hash] additional execution options to expect
#
# @return [RSpec::Mocks::MessageExpectation] the expectation object for chaining
#
# @example
#   expect_command_capturing('stash', 'apply').and_return(command_result(''))
#   expect_command_capturing('stash', 'push', '--all').and_return(command_result(''))
#   expect_command_capturing('fetch', 'origin', timeout: 30).and_return(command_result(''))
#   expect_command_capturing('fetch', 'origin', timeout: -1).and_raise(ArgumentError, 'Invalid timeout value')
#
def expect_command_capturing(*, **execution_options)
  expect(execution_context).to(
    receive(:command_capturing).with(*, **execution_options, raise_on_failure: false)
  )
end

# Helper to expect a streaming command call (non-capturing path)
#
# This helper simplifies testing commands that use the streaming execution path via
# Commands::Base, which always passes raise_on_failure: false to the execution context.
#
# @param args [Array] the command arguments to expect
#
# @param execution_options [Hash] additional execution options to expect
#
# @return [RSpec::Mocks::MessageExpectation] the expectation object for chaining
#
# @example
#   expect_command_streaming('cat-file', '--batch', out: StringIO.new).and_return(command_result(''))
#
def expect_command_streaming(*, **execution_options)
  expect(execution_context).to(
    receive(:command_streaming).with(*, **execution_options, raise_on_failure: false)
  )
end

# Create a test double for ExecutionContext with git_version stubbed
#
# This helper creates a consistent mock for the execution context used in
# command specs. By default, it returns a very high git version (99.99.99) so
# that all version-gated commands pass validation.
#
# @param version [String] the git version string to stub (default: '99.99.99')
#
# @return [RSpec::Mocks::Double] a test double with git_version stubbed
#
# @example
#   let(:execution_context) { execution_context_double }
#   let(:execution_context) { execution_context_double('2.30.0') }
#
def execution_context_double(version = '99.99.99')
  double('ExecutionContext', git_version: Git::Version.parse(version))
end

# Stub git_version on an existing execution context double
#
# @param context [RSpec::Mocks::Double] the execution context double to modify
# @param version [String] the git version string to stub
#
# @return [Git::Version] the version that git_version will return when called
#
# @example
#   stub_git_version(execution_context, '2.28.0')
#
def stub_git_version(context, version)
  git_version = Git::Version.parse(version)
  allow(context).to receive(:git_version).and_return(git_version)
  git_version
end
