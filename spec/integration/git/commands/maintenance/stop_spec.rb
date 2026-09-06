# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/maintenance/stop'

# `git maintenance stop` removes OS-level scheduler entries (launchctl on macOS,
# systemd-timer on Linux). Running it on a developer machine that has existing
# maintenance configured would silently disable their setup. Restricted to CI.
RSpec.describe Git::Commands::Maintenance::Stop, :integration,
               skip: unless_ci_build('git maintenance stop') do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  # Redirect all global config reads/writes to a temp file for isolation.
  #
  # The file handle is closed immediately after creation so that Windows does not hold an
  # exclusive lock on the file, which would prevent git from writing to it.
  let(:global_config) { Tempfile.new(['maintenance_global', '.conf']).tap(&:close) }
  let(:isolated_env) { { 'GIT_CONFIG_GLOBAL' => global_config.path } }

  after do
    global_config.close unless global_config.closed?
    global_config.unlink
  end

  describe '#call' do
    context 'when the command succeeds' do
      it 'returns a Git::CommandLine::Result' do
        result = command.call(env: isolated_env)

        expect(result).to be_a(Git::CommandLine::Result)
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
