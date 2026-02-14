# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/show_current'

RSpec.describe Git::Commands::Branch::ShowCurrent, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    describe 'when the command succeeds' do
      it 'returns a CommandLineResult with output' do
        write_file('README.md', 'Initial content')
        repo.add('README.md')
        repo.commit('Initial commit')

        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).not_to be_empty
      end

      it 'returns empty stdout in detached HEAD state' do
        write_file('README.md', 'Initial content')
        repo.add('README.md')
        repo.commit('Initial commit')
        commit_sha = repo.log.execute.first.sha
        repo.checkout(commit_sha)

        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout.strip).to be_empty
      end

      it 'returns the branch name on an unborn branch' do
        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout.strip).not_to be_empty
      end
    end

    describe 'when the command fails' do
      before { FileUtils.rm_rf(File.join(repo_dir, '.git')) }

      it 'raises FailedError when the repository is missing' do
        expect { command.call }.to raise_error(Git::FailedError)
      end
    end
  end
end
