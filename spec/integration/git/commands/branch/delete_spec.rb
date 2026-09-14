# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/delete'

RSpec.describe Git::Commands::Branch::Delete, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    before do
      write_file('file.txt', 'content')
      repo.add('file.txt')
      repo.commit('Initial commit')
    end

    describe 'when the command succeeds' do
      it 'returns exit code 0 when all branches deleted' do
        repo.branch_new('feature')

        result = command.call('feature')

        expect(result.status.exitstatus).to eq(0)
        expect(result.stdout).not_to be_empty
      end

      it 'returns exit code 1 for nonexistent branch' do
        # Exit code 1 does not raise, but exit code > 1 would
        result = command.call('nonexistent')

        expect(result).to be_a(Git::CommandLine::Result)
        expect(result.status.exitstatus).to eq(1)
      end

      it 'returns exit code 1 and keeps the branch when it is checked out' do
        current = repo.current_branch

        result = command.call(current)

        expect(result.status.exitstatus).to eq(1)
        expect(repo.local_branch?(current)).to be(true)
      end

      context 'with remotes: true' do
        let(:bare_dir) { Dir.mktmpdir('bare_repo') }

        before do
          Git.init(bare_dir, bare: true, initial_branch: 'main')
          repo.remote_add('origin', bare_dir)
          repo.branch_new('feature')
          repo.push('origin', 'feature')
        end

        after { FileUtils.rm_rf(bare_dir) }

        it 'deletes the remote-tracking ref and keeps the same-named local branch' do
          result = command.call('origin/feature', remotes: true)

          expect(result.status.exitstatus).to eq(0)
          expect(repo.local_branch?('feature')).to be(true)
          expect(repo.remote_branch?('feature')).to be(false)
        end
      end
    end

    describe 'when the command fails' do
      it 'raises Git::FailedError when git exits with code > 1' do
        FileUtils.rm_rf(File.join(repo_dir, '.git'))

        expect { command.call('any-branch') }.to raise_error(Git::FailedError)
      end
    end
  end
end
