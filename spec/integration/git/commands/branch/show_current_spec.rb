# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/show_current'
require 'git/detached_head_info'

RSpec.describe Git::Commands::Branch::ShowCurrent, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when on a branch' do
      before do
        write_file('README.md', 'Initial content')
        repo.add('README.md')
        repo.commit('Initial commit')
      end

      it 'returns the BranchInfo for the current branch' do
        result = command.call

        expect(result).to be_a(Git::BranchInfo)
        expect(result.short_name).to eq('main')
        expect(result.current?).to be true
      end
    end

    context 'when on a feature branch with slashes in the name' do
      before do
        write_file('README.md', 'Initial content')
        repo.add('README.md')
        repo.commit('Initial commit')
        repo.branch('feature/my-feature').checkout
      end

      it 'returns the BranchInfo for the feature branch' do
        result = command.call

        expect(result).to be_a(Git::BranchInfo)
        expect(result.short_name).to eq('feature/my-feature')
        expect(result.current?).to be true
      end
    end

    context 'when in detached HEAD state' do
      attr_reader :commit_sha

      before do
        write_file('README.md', 'Initial content')
        repo.add('README.md')
        repo.commit('Initial commit')

        # Get the commit SHA and checkout directly to it (detached HEAD)
        @commit_sha = repo.log.execute.first.sha
        repo.checkout(@commit_sha)
      end

      it 'returns a DetachedHeadInfo' do
        result = command.call

        expect(result).to be_a(Git::DetachedHeadInfo)
      end

      it 'includes the commit SHA' do
        result = command.call

        expect(result.target_oid).to eq(commit_sha)
      end

      it 'reports as detached' do
        result = command.call

        expect(result.detached?).to be true
        expect(result.short_name).to eq('HEAD')
      end
    end

    context 'when checking out a tag (detached HEAD)' do
      attr_reader :commit_sha

      before do
        write_file('README.md', 'Initial content')
        repo.add('README.md')
        repo.commit('Initial commit')
        @commit_sha = repo.log.execute.first.sha
        repo.add_tag('v1.0.0')
        repo.checkout('v1.0.0')
      end

      it 'returns a DetachedHeadInfo with the commit SHA' do
        result = command.call

        expect(result).to be_a(Git::DetachedHeadInfo)
        expect(result.target_oid).to eq(commit_sha)
        expect(result.detached?).to be true
      end
    end

    context 'when on an unborn branch (new repository with no commits)' do
      # No commits are made, so the branch is unborn

      it 'returns a BranchInfo for the unborn branch' do
        result = command.call

        expect(result).to be_a(Git::BranchInfo)
        expect(result.short_name).to eq('main')
        expect(result.current?).to be true
      end

      it 'reports as unborn (nil target_oid)' do
        result = command.call

        expect(result.target_oid).to be_nil
        expect(result.unborn?).to be true
      end

      it 'is not detached' do
        result = command.call

        expect(result.detached?).to be false
      end
    end

    context 'when on an orphan branch (created with --orphan)' do
      before do
        write_file('README.md', 'Initial content')
        repo.add('README.md')
        repo.commit('Initial commit')

        # Create an orphan branch - this starts a new history with no parent
        repo.checkout(orphan: 'orphan-branch')
      end

      it 'returns a BranchInfo for the orphan branch' do
        result = command.call

        expect(result).to be_a(Git::BranchInfo)
        expect(result.short_name).to eq('orphan-branch')
        expect(result.current?).to be true
      end

      it 'reports as unborn (nil target_oid) since no commit made yet' do
        result = command.call

        expect(result.target_oid).to be_nil
        expect(result.unborn?).to be true
      end

      it 'is not detached' do
        result = command.call

        expect(result.detached?).to be false
      end
    end
  end
end
