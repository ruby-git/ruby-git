# frozen_string_literal: true

# Force unbuffered output so that CI logs show progress even if the process hangs
# before a normal exit (Fuubar/ruby-progressbar buffers output in non-TTY mode).
$stdout.sync = true
$stderr.sync = true

# On JRuby, print a loading-phase marker so that CI logs can distinguish a hang
# during file loading from a hang during a specific test. Without this, a hang
# before the first RSpec example produces no output at all.
warn "[spec_helper] JRuby #{RUBY_VERSION}: beginning spec_helper load" if RUBY_ENGINE == 'jruby'

# Load support files
Dir[File.join(__dir__, 'support', '**', '*.rb')].each do |f|
  warn "[spec_helper] requiring #{f}" if RUBY_ENGINE == 'jruby'
  require f
end

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

  # Choose the formatter here (rather than a static --format in .rspec), since Fuubar
  # isn't the right choice for every case:
  #
  # - Single-file run (focused debugging) or JRuby (so a hang's last printed line
  #   identifies the blocking test): plain per-example output is more useful than a
  #   progress bar.
  # - Under parallel_tests (ENV['TEST_ENV_NUMBER'] is set for every worker, including
  #   the first): multiple worker processes redraw Fuubar's progress bar on the same
  #   terminal line concurrently, corrupting the output. Plain dots don't redraw, so
  #   they interleave safely.
  config.default_formatter =
    if (config.files_to_run.one? && !ENV['TEST_ENV_NUMBER']) || RUBY_ENGINE == 'jruby'
      'documentation'
    elsif ENV['TEST_ENV_NUMBER']
      'progress'
    else
      'Fuubar'
    end

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

  # Raise on any Git::Deprecation.warn call so that deprecated code paths are
  # caught immediately as test failures. Tests that intentionally exercise a
  # deprecated method must wrap the call in Git::Deprecation.silence { ... }
  # to suppress the raise for that specific invocation.
  #
  # Use before(:suite) to apply globally (including before(:all) hooks) and
  # after(:suite) to restore original behavior to avoid leaking global state.
  config.before(:suite) do
    @original_deprecation_behavior = Git::Deprecation.behavior
    Git::Deprecation.behavior = :raise
  end

  config.after(:suite) do
    Git::Deprecation.behavior = @original_deprecation_behavior
  end
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

# Returns `false` if `command` is found on `PATH`, otherwise a skip-reason string.
# Use as the `skip:` metadata value for tests that depend on an optional external
# executable (e.g. `ssh-keygen`) not guaranteed to be present in every test
# environment.
#
# @param command [String] the executable name to look up on `PATH`
#
# @param feature [String] the feature name to include in the skip reason
#
# @return [false, String] `false` if `command` is found on `PATH`; otherwise a
#   human-readable skip reason string
#
# @example Skip an example group when ssh-keygen is unavailable
#   RSpec.describe MyFeature, skip: unless_command('ssh-keygen', 'SSH commit signing') do
#     it 'works' do
#       # ...
#     end
#   end
#
def unless_command(command, feature)
  found = ENV.fetch('PATH', '').split(File::PATH_SEPARATOR).any? do |dir|
    File.executable?(File.join(dir, command)) && !File.directory?(File.join(dir, command))
  end

  return false if found

  "#{feature} requires the `#{command}` executable, which was not found on PATH"
end

def ci_build? = ENV.fetch('GITHUB_ACTIONS', 'false') == 'true'

# The value ruby-git pins `LC_ALL` to on this host
#
# Mirrors the platform-conditional pin in `Git::ExecutionContext#env_overrides` so
# that specs which merely pass through the git environment can assert on it without
# hardcoding a literal that is only correct on one platform family. Specs that are
# *about* the pin stub `RUBY_PLATFORM` and `RUBY_DESCRIPTION` and assert literals
# instead, so every branch stays covered on every host.
#
# @return [String] the `LC_ALL` value expected on the current platform
#
def expected_lc_all = darwin_platform? ? 'en_US.UTF-8' : 'C.UTF-8'

# Whether these specs are running on macOS
#
# Checks `RUBY_DESCRIPTION` as well as `RUBY_PLATFORM` because JRuby reports
# `RUBY_PLATFORM` as `"java"` on every host. Mirrors
# `Git::ExecutionContext#darwin_platform?`.
#
# @return [Boolean] true if these specs are running on macOS
#
def darwin_platform? = RUBY_PLATFORM.include?('darwin') || RUBY_DESCRIPTION.include?('darwin')

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

# Skip coverage when the COVERAGE environment variable is set to a falsy value
def coverage_disabled_via_env?
  coverage_env = ENV.fetch('COVERAGE', 'true').strip.downcase
  %w[false 0 no off].include?(coverage_env)
end

# Skip coverage if disabled via the COVERAGE env var or on non-MRI runtimes
#
# JRuby and TruffleRuby do not provide reliable coverage data and SimpleCov's branch
# coverage crashes on TruffleRuby 24.2.1.
#
def enable_coverage? = RUBY_ENGINE == 'ruby' && !coverage_disabled_via_env?

# Returns true when this run is the complete unit suite (`rake spec:unit` with no
# SPEC filter), false for any focused subset.
#
# The 100% thresholds are only meaningful for the whole unit suite. spec_helper
# does `require 'git'`, so a focused run (`SPEC=<glob> rake spec:unit`, or
# `rspec <file>`) loads all of lib/ but exercises only a slice of it -- enforcing
# thresholds there would fail every time and push contributors toward disabling
# coverage entirely. Coverage is still measured and reported for those runs; it
# just doesn't fail them.
#
# FAIL_ON_LOW_COVERAGE takes precedence over this value in simplecov-rspec, so
# `FAIL_ON_LOW_COVERAGE=true` can still force enforcement on for a subset run.
#
def full_unit_suite?
  files_run = RSpec.configuration.files_to_run.map { |f| File.expand_path(f) }.sort
  all_unit_specs = Dir[File.join(__dir__, 'unit', '**', '*_spec.rb')].map { |f| File.expand_path(f) }.sort

  files_run == all_unit_specs
end

# The lib/ files a focused run is actually about, for scoping the uncovered listing
#
# Two independent signals, unioned, because each covers the other's gap:
#
# - What the run described, via simplecov-rspec's `described_source_files` (the same
#   thing `list_uncovered_files: :described` scopes to). Handles the classes that
#   don't get their own file, e.g. `Git::TimeoutError` lives in lib/git/errors.rb
#   alongside its siblings.
# - The mirrored path. Handles the specs whose top-level `describe` is a String, e.g.
#   `RSpec.describe 'Git::VERSION'`, which yields no described_class at all.
#
# Passed to simplecov-rspec as a callable: SimpleCov::RSpec.start runs before any
# example group is defined, so neither signal exists yet at that point. This narrows
# only the listing, never the measured percentage.
#
def code_under_test
  (SimpleCov::RSpec.described_source_files + mirrored_source_files).uniq
end

# The lib/ file each spec file mirrors, for the specs that mirror one
def mirrored_source_files
  RSpec.configuration.files_to_run.filter_map do |spec_file|
    source = File.expand_path(spec_file).sub(%r{/spec/unit/}, '/lib/').sub(/_spec\.rb\z/, '.rb')
    source if File.file?(source)
  end
end

if enable_coverage?
  require 'simplecov'
  require 'simplecov-rspec'

  if ci_build?
    require 'simplecov-lcov'

    SimpleCov.formatters = [
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::LcovFormatter
    ]
  end

  SimpleCov.enable_coverage :branch

  # The project requires 100% line and branch coverage of lib/ from the unit suite.
  # See the "Test coverage policy" section of CONTRIBUTING.md.
  #
  # The uncovered listing is always detailed, because it is always scoped to code the
  # run is about. For the full suite that costs nothing at 100% (there is nothing to
  # print) and makes a failing CI log self-diagnosing by naming the exact uncovered
  # lines and branches. For a focused run, list_uncovered_files narrows it to the
  # handful of lib/ files under test, so the detail is short and directly actionable
  # instead of the thousands of lines the whole of lib/ would produce.
  # LIST_UNCOVERED_DETAIL and LIST_UNCOVERED_FILES override this either way.
  #
  SimpleCov::RSpec.start(
    minimum_coverage: { line: 100, branch: 100 },
    fail_on_low_coverage: full_unit_suite?,
    list_uncovered: %i[branch line],
    list_uncovered_detail: true,
    list_uncovered_files: full_unit_suite? ? nil : -> { code_under_test }
  ) do
    command_name "RSpec-#{ENV['TEST_ENV_NUMBER']}" if ENV['TEST_ENV_NUMBER']
  end
end

require 'git'

warn '[spec_helper] spec_helper fully loaded' if RUBY_ENGINE == 'jruby'

# Helper to create a mock CommandLineResult for use in specs
#
# @param stdout [String] the stdout to return
# @param stderr [String] the stderr to return (default: '')
# @param exitstatus [Integer] the exit status code (default: 0)
# @return [Git::CommandLine::Result] a CommandLineResult object
def command_result(stdout = '', stderr: '', exitstatus: 0)
  status = double('status', success?: exitstatus.zero?, exitstatus: exitstatus, signaled?: false)
  Git::CommandLine::Result.new(%w[git], status, stdout, stderr)
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
