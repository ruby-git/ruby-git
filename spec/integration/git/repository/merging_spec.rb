# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/merging'

RSpec.describe Git::Repository::Merging, :integration do
  include_context 'in an empty repository'

  let(:execution_context) { Git::ExecutionContext::Repository.from_base(repo) }
  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  # Create an initial commit on the default branch so we have a proper HEAD
  before do
    write_file('README.md', "# Hello\n")
    repo.add('README.md')
    repo.commit('Initial commit')
  end

  # ---------------------------------------------------------------------------
  # #merge — single branch
  # ---------------------------------------------------------------------------

  describe '#merge single branch' do
    before do
      # Create and populate a feature branch
      repo.lib.branch_new('feature')
      repo.lib.checkout('feature')
      write_file('feature.txt', "feature content\n")
      repo.add('feature.txt')
      repo.commit('Add feature file')
      repo.lib.checkout('main')
    end

    it 'returns a String' do
      result = described_instance.merge('feature')
      expect(result).to be_a(String)
    end

    it 'merges the feature branch into the current branch' do
      described_instance.merge('feature')
      expect(File.exist?(File.join(repo_dir, 'feature.txt'))).to be(true)
    end

    it 'makes the merged file visible in git status' do
      described_instance.merge('feature')
      # After a clean merge, status should show no untracked/modified files
      expect(repo.status.added).to be_empty
      expect(repo.status.changed).to be_empty
    end
  end

  # ---------------------------------------------------------------------------
  # #merge — Git::Branch object coercion
  # ---------------------------------------------------------------------------

  describe '#merge with a Git::Branch object' do
    before do
      repo.lib.branch_new('feature')
      repo.lib.checkout('feature')
      write_file('from_branch_obj.txt', "branch object content\n")
      repo.add('from_branch_obj.txt')
      repo.commit('Add from_branch_obj.txt')
      repo.lib.checkout('main')
    end

    it 'coerces the Git::Branch to a String and merges successfully' do
      branch_obj = repo.branch('feature')
      described_instance.merge(branch_obj)
      expect(File.exist?(File.join(repo_dir, 'from_branch_obj.txt'))).to be(true)
    end
  end

  # ---------------------------------------------------------------------------
  # #merge — Array of branches (octopus merge)
  # ---------------------------------------------------------------------------

  describe '#merge octopus (Array of branches)' do
    before do
      repo.lib.branch_new('branch-a')
      repo.lib.checkout('branch-a')
      write_file('file_a.txt', "content from branch-a\n")
      repo.add('file_a.txt')
      repo.commit('Add file_a.txt')
      repo.lib.checkout('main')

      repo.lib.branch_new('branch-b')
      repo.lib.checkout('branch-b')
      write_file('file_b.txt', "content from branch-b\n")
      repo.add('file_b.txt')
      repo.commit('Add file_b.txt')
      repo.lib.checkout('main')
    end

    it 'merges all branches and all files appear in the working tree' do
      described_instance.merge(%w[branch-a branch-b])
      expect(File.exist?(File.join(repo_dir, 'file_a.txt'))).to be(true)
      expect(File.exist?(File.join(repo_dir, 'file_b.txt'))).to be(true)
    end

    it 'returns a String' do
      result = described_instance.merge(%w[branch-a branch-b])
      expect(result).to be_a(String)
    end
  end

  # ---------------------------------------------------------------------------
  # #merge — no_ff: true with a commit message
  # ---------------------------------------------------------------------------

  describe '#merge with no_ff: true and a message' do
    before do
      repo.lib.branch_new('feature')
      repo.lib.checkout('feature')
      write_file('noff.txt', "no-ff content\n")
      repo.add('noff.txt')
      repo.commit('Add noff.txt')
      repo.lib.checkout('main')
    end

    it 'creates a merge commit whose message is the given string' do
      described_instance.merge('feature', 'merge commit message', no_ff: true)
      commits = repo.log.execute
      expect(commits.first.message).to eq('merge commit message')
    end

    it 'makes the merged file visible in the working tree' do
      described_instance.merge('feature', 'merge commit message', no_ff: true)
      expect(File.exist?(File.join(repo_dir, 'noff.txt'))).to be(true)
    end
  end

  # ---------------------------------------------------------------------------
  # #merge — fast-forward with message (git ignores -m on ff)
  # ---------------------------------------------------------------------------

  describe '#merge fast-forward with a message' do
    before do
      repo.lib.branch_new('feature')
      repo.lib.checkout('feature')
      write_file('ff.txt', "ff content\n")
      repo.add('ff.txt')
      repo.commit('first commit message')
      repo.lib.checkout('main')
    end

    it 'performs the merge successfully (returns a String)' do
      result = described_instance.merge('feature', 'merge commit message')
      expect(result).to be_a(String)
    end

    it 'merges the file into the working tree' do
      described_instance.merge('feature', 'merge commit message')
      expect(File.exist?(File.join(repo_dir, 'ff.txt'))).to be(true)
    end

    it 'does NOT set the commit message (git ignores -m on fast-forward merges)' do
      described_instance.merge('feature', 'merge commit message')
      commits = repo.log.execute
      expect(commits.first.message).to eq('first commit message')
    end
  end

  # ---------------------------------------------------------------------------
  # #merge — no_commit: true (HEAD unchanged after merge)
  #
  # NOTE: git ignores --no-commit on fast-forward merges. The test therefore
  # creates a divergent history (main has a commit that feature does not) so
  # that a real three-way merge is required and --no-commit takes effect.
  # ---------------------------------------------------------------------------

  describe '#merge with no_commit: true' do
    before do
      # Branch feature off the initial commit
      repo.lib.branch_new('feature')
      repo.lib.checkout('feature')
      write_file('staged.txt', "staged content\n")
      repo.add('staged.txt')
      repo.commit('Add staged.txt')
      repo.lib.checkout('main')

      # Create a commit on main so that main and feature have diverged;
      # this prevents a fast-forward and makes --no-commit effective.
      write_file('main_only.txt', "main content\n")
      repo.add('main_only.txt')
      repo.commit('Add main_only.txt')
    end

    it 'leaves HEAD pointing at the pre-merge commit' do
      head_before = repo.log(1).execute.first.sha
      described_instance.merge('feature', nil, no_commit: true)
      expect(repo.log(1).execute.first.sha).to eq(head_before)
    end

    it 'stages the merge result but does not create a commit' do
      described_instance.merge('feature', nil, no_commit: true)
      # The file is staged (type 'A') but no new commit was made
      status = repo.status['staged.txt']
      expect(status).not_to be_nil
      expect(status.type).to eq('A')
    end
  end

  # ---------------------------------------------------------------------------
  # #merge_base — basic ancestor lookup
  # ---------------------------------------------------------------------------

  describe '#merge_base' do
    before do
      # Record the SHA of the initial commit — that is the common ancestor
      @common_ancestor_sha = repo.log(1).execute.first.sha

      # Add a commit on feature that is NOT on main
      repo.lib.branch_new('feature')
      repo.lib.checkout('feature')
      write_file('feature.txt', "feature\n")
      repo.add('feature.txt')
      repo.commit('Feature commit')
      repo.lib.checkout('main')

      # Add a commit on main that is NOT on feature (forces a real divergence)
      write_file('main_extra.txt', "main extra\n")
      repo.add('main_extra.txt')
      repo.commit('Main extra commit')
    end

    it 'returns an Array' do
      result = described_instance.merge_base('main', 'feature')
      expect(result).to be_an(Array)
    end

    it 'returns an Array of String SHAs' do
      result = described_instance.merge_base('main', 'feature')
      expect(result).to all(be_a(String))
    end

    it 'returns the correct common ancestor SHA' do
      result = described_instance.merge_base('main', 'feature')
      expect(result).to eq([@common_ancestor_sha])
    end
  end

  # ---------------------------------------------------------------------------
  # #merge_base — all: true returns multiple bases when they exist
  # ---------------------------------------------------------------------------

  describe '#merge_base with all: true' do
    before do
      # Build a criss-cross merge history so there are two equally good bases.
      #
      # Starting from the initial commit A on main, diverge two independent
      # branches — B (new_branch_1) and C (new_branch_2) — then cross-merge:
      #
      #   A ─── B (nb1) ─── merge(B,C) M1
      #     └── C (nb2) ─── merge(C,B) M2
      #
      # merge_base(M1, M2) returns both B and C.

      # B: commit on new_branch_1 (branches off main/A)
      repo.lib.branch_new('new_branch_1')
      repo.lib.checkout('new_branch_1')
      write_file('b1_1.txt', "b1 first\n")
      repo.add('b1_1.txt')
      repo.commit('B: first commit on branch 1')
      @first_commit_sha = repo.log(1).execute.first.sha

      # C: commit on new_branch_2 (branches off main/A independently)
      repo.lib.checkout('main')
      repo.lib.branch_new('new_branch_2')
      repo.lib.checkout('new_branch_2')
      write_file('b2_1.txt', "b2 first\n")
      repo.add('b2_1.txt')
      repo.commit('C: first commit on branch 2')
      @second_commit_sha = repo.log(1).execute.first.sha

      # M2: nb2 merges B → merge commit with parents C and B
      repo.merge(@first_commit_sha.to_s)

      # M1: nb1 merges C → merge commit with parents B and C
      repo.lib.checkout('new_branch_1')
      repo.merge(@second_commit_sha.to_s)
    end

    it 'returns more than one ancestor when multiple equally good bases exist' do
      result = described_instance.merge_base('new_branch_1', 'new_branch_2', all: true)
      expect(result.size).to be >= 2
    end

    it 'returns Array<String> SHAs' do
      result = described_instance.merge_base('new_branch_1', 'new_branch_2', all: true)
      expect(result).to all(be_a(String))
    end
  end
end
