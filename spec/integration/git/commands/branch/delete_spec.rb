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
      it 'returns a CommandLineResult with output' do
        repo.branch('feature').create

        result = command.call('feature')

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).not_to be_empty
      end

      it 'returns exit code 0 when all branches deleted' do
        repo.branch('feature').create

        result = command.call('feature')

        expect(result.status.exitstatus).to eq(0)
        expect(result.stdout).not_to be_empty
      end

      it 'returns exit code 1 for partial failure' do
        repo.branch('exists').create

        result = command.call('exists', 'nonexistent')

        expect(result.status.exitstatus).to eq(1)
      end

      it 'returns exit code 1 for nonexistent branch' do
        # Exit code 1 does not raise, but exit code > 1 would
        result = command.call('nonexistent')

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.exitstatus).to eq(1)
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
