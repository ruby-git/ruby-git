# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/maintenance/start'
require 'git/commands/maintenance/stop'

# GIT_CONFIG_GLOBAL (used for global config isolation) requires git 2.32.0,
# so these integration tests require 2.32.0 even though the command itself supports 2.30.0.
#
# `git maintenance start` installs OS-level scheduler entries (launchctl on macOS,
# systemd-timer on Linux) that cannot be safely redirected. These tests are therefore
# restricted to CI where the environment is guaranteed clean.
RSpec.describe Git::Commands::Maintenance::Start, :integration,
               skip: unless_git('2.32.0', 'git maintenance start') ||
                     unless_ci_build('git maintenance start') do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  # Redirect all global config writes to a temp file to avoid polluting ~/.gitconfig.
  # GIT_CONFIG_GLOBAL is honoured by every git invocation regardless of whether the
  # command exposes a --config-file option.
  #
  # The file handle is closed immediately after creation so that Windows does not hold an
  # exclusive lock on the file, which would prevent git from writing to it.
  let(:global_config) { Tempfile.new(['maintenance_global', '.conf']).tap(&:close) }
  let(:isolated_env) { { 'GIT_CONFIG_GLOBAL' => global_config.path } }

  after do
    Git::Commands::Maintenance::Stop.new(execution_context).call(env: isolated_env)
  rescue Git::FailedError
    # Ignore stop failures (e.g. when start itself failed or repo was removed)
    nil
  ensure
    global_config.close unless global_config.closed?
    global_config.unlink
  end

  describe '#call' do
    context 'when the command succeeds' do
      it 'returns a CommandLineResult' do
        result = command.call(env: isolated_env)

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'returns exit code 0' do
        result = command.call(env: isolated_env)

        expect(result.status.exitstatus).to eq(0)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError when not in a git repository' do
        FileUtils.rm_rf(File.join(repo_dir, '.git'))

        expect { command.call(env: isolated_env) }.to raise_error(Git::FailedError)
      end
    end
  end
end
