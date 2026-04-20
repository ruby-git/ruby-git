# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/maintenance/run'

# GIT_CONFIG_GLOBAL (used for global config isolation) requires git 2.32.0,
# so these integration tests require 2.32.0 even though the command itself supports 2.30.0.
RSpec.describe Git::Commands::Maintenance::Run, :integration,
               skip: unless_git('2.32.0', 'git maintenance run') do
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
