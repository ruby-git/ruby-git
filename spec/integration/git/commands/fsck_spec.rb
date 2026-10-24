# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/fsck'

RSpec.describe Git::Commands::Fsck, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when the command succeeds' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
      end

      it 'returns exit code 0 when the repository is intact' do
        result = command.call

        expect(result).to be_a(Git::CommandLine::Result)
        expect(result.status.exitstatus).to eq(0)
      end

      it 'returns exit code 2 when a branch points at a ref that does not exist' do
        execution_context.command_capturing('symbolic-ref', 'refs/heads/broken', 'refs/heads/missing')

        result = command.call

        expect(result.status.exitstatus).to eq(2)
        expect(result.stderr).to include('refs/heads/broken')
      end
    end

    context 'when the command fails' do
      it 'raises FailedError when not in a git repository' do
        # Removing the repository makes git exit 128, outside the allowed range
        FileUtils.rm_rf(File.join(repo_dir, '.git'))

        # git's "not a git repository" message varies across versions, so anchor on stable text
        expect { command.call }.to raise_error(Git::FailedError, /git repository/)
      end
    end
  end
end
