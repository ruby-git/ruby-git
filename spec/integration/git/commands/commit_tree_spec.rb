# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/commit_tree'

RSpec.describe Git::Commands::CommitTree, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  # Create an initial commit so we have a tree and a parent to work with
  let(:initial_commit_sha) do
    write_file('file.txt', "content\n")
    repo.add('file.txt')
    repo.commit('Initial commit')
    repo.revparse('HEAD')
  end

  let(:tree_sha) { repo.revparse('HEAD^{tree}') }

  before { initial_commit_sha }

  describe '#call' do
    context 'when the command succeeds' do
      it 'returns a CommandLineResult with the new commit SHA on stdout' do
        result = command.call(tree_sha, m: 'Test commit')

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).to match(/\A[0-9a-f]{40}\z/)
      end

      it 'creates a commit with the specified parent' do
        result = command.call(tree_sha, p: initial_commit_sha, m: 'Child commit')
        new_sha = result.stdout

        # Verify the parent relationship using cat-file
        commit_content = execution_context.command_capturing('cat-file', '-p', new_sha).stdout
        expect(commit_content).to include("parent #{initial_commit_sha}")
      end

      it 'creates a merge commit with multiple parents' do
        # Create a second branch with a different commit
        second_sha = command.call(tree_sha, p: initial_commit_sha, m: 'Second branch').stdout

        result = command.call(
          tree_sha,
          p: [initial_commit_sha, second_sha],
          m: 'Merge commit'
        )

        commit_content = execution_context.command_capturing('cat-file', '-p', result.stdout).stdout
        expect(commit_content).to include("parent #{initial_commit_sha}")
        expect(commit_content).to include("parent #{second_sha}")
      end
    end

    context 'when the command fails' do
      it 'raises FailedError for an invalid tree' do
        expect { command.call('0000000000000000000000000000000000000000', m: 'bad') }
          .to raise_error(Git::FailedError, /0000000000000000000000000000000000000000/)
      end
    end
  end
end
