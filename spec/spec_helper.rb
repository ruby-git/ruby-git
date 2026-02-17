# frozen_string_literal: true

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
require 'simplecov'
require 'simplecov-lcov'
require 'simplecov-rspec'

def ci_build? = ENV.fetch('GITHUB_ACTIONS', 'false') == 'true'

if ci_build?
  SimpleCov.formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::LcovFormatter
  ]
end

SimpleCov::RSpec.start(
  coverage_threshold: 100,
  fail_on_low_coverage: false,
  list_uncovered_lines: false
)

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
#   expect_command('stash', 'apply').and_return(command_result(''))
#   expect_command('stash', 'push', '--all').and_return(command_result(''))
#   expect_command('fetch', 'origin', timeout: 30).and_return(command_result(''))
#
def expect_command(*, **execution_options)
  expect(execution_context).to receive(:command)
    .with(*, **execution_options, raise_on_failure: false)
end
