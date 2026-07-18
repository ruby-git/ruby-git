# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/merging'

RSpec.describe Git::Repository::Merging, :integration do
  include_context 'in an empty repository'

  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  # Create an initial commit on the default branch so we have a proper HEAD
  before do
    write_file('README.md', "# Hello\n")
    repo.add('README.md')
    repo.commit('Initial commit')
  end

  describe '#merge' do
    context 'with a Git::BranchInfo object' do
      let(:branch_info) { repo.branch_list.find { |info| info.refname == 'refs/heads/feature' } }
      let(:merged_file_path) { File.join(repo_dir, 'from_branch_info.txt') }

      before do
        repo.branch_new('feature')
        repo.checkout('feature')
        write_file('from_branch_info.txt', "branch info content\n")
        repo.add('from_branch_info.txt')
        repo.commit('Add from_branch_info.txt')
        repo.checkout('main')
      end

      it 'coerces it to a String and merges successfully' do
        expect { described_instance.merge(branch_info) }
          .to change { File.exist?(merged_file_path) }.from(false).to(true)
      end
    end

    context 'with a message on a fast-forward merge' do
      before do
        repo.branch_new('feature')
        repo.checkout('feature')
        write_file('ff.txt', "ff content\n")
        repo.add('ff.txt')
        repo.commit('first commit message')
        repo.checkout('main')
      end

      it 'keeps the fast-forwarded commit message' do
        described_instance.merge('feature', 'merge commit message')
        expect(repo.log.execute.first.message).to eq('first commit message')
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #merge_base — basic ancestor lookup
  # ---------------------------------------------------------------------------

  describe '#merge_base' do
    subject(:result) { described_instance.merge_base(*merge_base_args, **merge_base_options) }

    let(:merge_base_args) { %w[main feature] }
    let(:merge_base_options) { {} }

    context 'when branches have one common ancestor' do
      let!(:common_ancestor_sha) { repo.log(1).execute.first.sha }

      before do
        # Add a commit on feature that is NOT on main
        repo.branch_new('feature')
        repo.checkout('feature')
        write_file('feature.txt', "feature\n")
        repo.add('feature.txt')
        repo.commit('Feature commit')
        repo.checkout('main')

        # Add a commit on main that is NOT on feature (forces a real divergence)
        write_file('main_extra.txt', "main extra\n")
        repo.add('main_extra.txt')
        repo.commit('Main extra commit')
      end

      it 'returns the common ancestor SHA' do
        expect(result).to eq([common_ancestor_sha])
      end
    end

    context 'with all: true when multiple bases exist' do
      let(:merge_base_args) { %w[new_branch_1 new_branch_2] }
      let(:merge_base_options) { { all: true } }

      let!(:first_commit_sha) do
        repo.branch_new('new_branch_1')
        repo.checkout('new_branch_1')
        write_file('b1_1.txt', "b1 first\n")
        repo.add('b1_1.txt')
        repo.commit('B: first commit on branch 1')
        repo.log(1).execute.first.sha
      end

      let!(:second_commit_sha) do
        repo.checkout('main')
        repo.branch_new('new_branch_2')
        repo.checkout('new_branch_2')
        write_file('b2_1.txt', "b2 first\n")
        repo.add('b2_1.txt')
        repo.commit('C: first commit on branch 2')
        repo.log(1).execute.first.sha
      end

      before do
        # Build a criss-cross merge history so there are two equally good bases.
        repo.merge(first_commit_sha.to_s)
        repo.checkout('new_branch_1')
        repo.merge(second_commit_sha.to_s)
      end

      it 'returns both equally good common ancestor SHAs' do
        expect(result).to contain_exactly(first_commit_sha, second_commit_sha)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #unmerged
  # ---------------------------------------------------------------------------

  describe '#unmerged' do
    subject(:result) { described_instance.unmerged }

    context 'when there are no conflicts' do
      it 'returns an empty Array' do
        expect(result).to eq([])
      end
    end

    context 'when there is a conflict' do
      before do
        repo.branch_new('branch_ours')
        repo.checkout('branch_ours')
        write_file('example.txt', "1\n2\n3\n")
        repo.add('example.txt')
        repo.commit('ours: add example.txt')

        repo.checkout('main')
        repo.branch_new('branch_theirs')
        repo.checkout('branch_theirs')
        write_file('example.txt', "1\n4\n3\n")
        repo.add('example.txt')
        repo.commit('theirs: add example.txt')

        repo.checkout('main')
        repo.merge('branch_ours')

        begin
          repo.merge('branch_theirs')
        rescue Git::FailedError
          # expected conflict
        end
      end

      it 'returns the conflicting file path(s)' do
        expect(result).to include('example.txt')
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #each_conflict
  # ---------------------------------------------------------------------------

  describe '#each_conflict' do
    subject(:result) { described_instance.each_conflict { nil } }

    context 'when there are no conflicts' do
      it 'does not yield' do
        expect { |b| described_instance.each_conflict(&b) }.not_to yield_control
      end

      it 'returns an empty Array' do
        expect(result).to eq([])
      end
    end

    context 'when there is a conflict' do
      before do
        repo.branch_new('branch_ours')
        repo.checkout('branch_ours')
        write_file('example.txt', "1\n2\n3\n")
        repo.add('example.txt')
        repo.commit('ours: add example.txt')

        repo.checkout('main')
        repo.branch_new('branch_theirs')
        repo.checkout('branch_theirs')
        write_file('example.txt', "1\n4\n3\n")
        repo.add('example.txt')
        repo.commit('theirs: add example.txt')

        repo.checkout('main')
        repo.merge('branch_ours')

        begin
          repo.merge('branch_theirs')
        rescue Git::FailedError
          # expected conflict
        end
      end

      it 'yields once for the conflicting file' do
        expect { |b| described_instance.each_conflict(&b) }.to yield_control.once
      end

      it 'yields the relative path of the conflicting file as the first argument' do
        described_instance.each_conflict do |file, _your, _their|
          expect(file).to eq('example.txt')
        end
      end

      it 'yields a readable path for your_version containing stage-2 content' do
        described_instance.each_conflict do |_file, your, _their|
          expect(File.read(your)).to eq("1\n2\n3\n")
        end
      end

      it 'yields a readable path for their_version containing stage-3 content' do
        described_instance.each_conflict do |_file, _your, their|
          expect(File.read(their)).to eq("1\n4\n3\n")
        end
      end

      it 'returns an Array of unmerged file paths' do
        expect(result).to eq(['example.txt'])
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #revert
  # ---------------------------------------------------------------------------

  describe '#revert' do
    before do
      write_file('feature.txt', "feature content\n")
      repo.add('feature.txt')
      repo.commit('Add feature file')
    end

    it 'treats a nil commitish as HEAD and reverts HEAD' do
      expect { described_instance.revert(nil) }
        .to change { repo.log(10_000).execute.count }.by(1)
    end
  end
end
