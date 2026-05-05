# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/committing'

# Integration-level coverage notes:
#
# Single-command delegator methods (#commit, #commit_all, #commit_tree,
# #write_tree) are covered end-to-end by the underlying command integration
# tests:
#   spec/integration/git/commands/commit_spec.rb
#   spec/integration/git/commands/commit_tree_spec.rb
#   spec/integration/git/commands/write_tree_spec.rb
#
# The integration test below covers only #write_and_commit_tree, which
# performs multi-command orchestration (write_tree followed by commit_tree)
# and warrants an end-to-end test to confirm the sequence produces the
# correct result against real git.

RSpec.describe Git::Repository::Committing, :integration do
  include_context 'in an empty repository'

  let(:execution_context) { Git::ExecutionContext::Repository.from_base(repo) }
  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  # Create an initial commit so the index has a tree to write
  before do
    write_file('file.txt', "initial content\n")
    repo.add('file.txt')
    repo.commit('Initial commit')
  end

  describe '#write_and_commit_tree' do
    context 'with a message option' do
      it 'returns a 40-character commit SHA string' do
        result = described_instance.write_and_commit_tree(message: 'snapshot')

        expect(result).to match(/\A[0-9a-f]{40}\z/)
      end

      it 'creates a commit whose tree matches the current index' do
        index_tree = described_instance.write_tree.strip
        commit_sha = described_instance.write_and_commit_tree(message: 'snapshot')
        commit_tree = execution_context.command_capturing('cat-file', '-p', commit_sha.strip)
                                       .stdout
                                       .then { |s| s[/^tree ([0-9a-f]{40})/, 1] }

        expect(commit_tree).to eq(index_tree)
      end
    end

    context 'with no options (default message)' do
      it 'returns a 40-character commit SHA string' do
        result = described_instance.write_and_commit_tree

        expect(result).to match(/\A[0-9a-f]{40}\z/)
      end
    end
  end
end
