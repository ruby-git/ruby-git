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

  describe '#commit' do
    context 'with an empty message' do
      it 'raises Git::FailedError' do
        expect { described_instance.commit('', allow_empty: true) }
          .to raise_error(Git::FailedError, /empty commit message|Aborting commit/i)
      end
    end

    context 'with an empty message and allow_empty_message: true' do
      it 'creates a commit and returns a String' do
        result = described_instance.commit('', allow_empty: true, allow_empty_message: true)

        expect(result).to be_a(String)
        expect(repo.log.execute.to_a.size).to be >= 2
      end
    end
  end

  describe '#set_index' do
    let(:custom_index_path) { File.join(repo_dir, 'custom_index') }

    after { FileUtils.rm_rf(custom_index_path) }

    context 'with a programmatic commit workflow' do
      it 'creates a new commit on a separate branch without touching the working tree' do
        main_commit = repo.gcommit('main')

        described_instance.set_index(custom_index_path, must_exist: false)
        described_instance.read_tree(main_commit.gtree.sha)

        new_tree_sha = described_instance.write_tree.strip
        new_commit = described_instance.commit_tree(
          new_tree_sha,
          parents: [main_commit.sha],
          message: 'Programmatic commit via custom index'
        )

        expect(new_commit.strip).to match(/\A[0-9a-f]{40}\z/)

        repo.branch('feature-branch').update_ref(new_commit.strip)
        feature_log = repo.log.object('feature-branch').execute

        expect(feature_log.to_a.size).to eq(2)
        expect(repo.log.object('main').execute.to_a.size).to eq(1)
      end
    end
  end
end
