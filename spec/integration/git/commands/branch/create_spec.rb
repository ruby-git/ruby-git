# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/create'

RSpec.describe Git::Commands::Branch::Create, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when creating a basic branch' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
      end

      it 'creates the branch and returns BranchInfo' do
        result = command.call('feature-branch')

        expect(result).to be_a(Git::BranchInfo)
        expect(result.refname).to eq('feature-branch')
      end

      it 'creates a local branch (not remote)' do
        result = command.call('feature-branch')

        expect(result.remote?).to be false
        expect(result.remote_name).to be_nil
      end

      it 'creates an unchecked-out branch' do
        result = command.call('feature-branch')

        expect(result.current?).to be false
        expect(result.worktree?).to be false
      end

      it 'makes the branch visible in the repository' do
        command.call('feature-branch')

        branch_list = repo.branches.local.map(&:name)
        expect(branch_list).to include('feature-branch')
      end

      it 'returns the short_name correctly' do
        result = command.call('feature-branch')

        expect(result.short_name).to eq('feature-branch')
      end
    end

    context 'when creating a branch from a specific start point' do
      let(:first_commit_sha) do
        write_file('file1.txt', 'content1')
        repo.add('file1.txt')
        repo.commit('First commit')
        execution_context.command('rev-parse', 'HEAD').stdout.strip
      end

      before do
        first_commit_sha # Create first commit and capture SHA
        write_file('file2.txt', 'content2')
        repo.add('file2.txt')
        repo.commit('Second commit')
      end

      it 'creates a branch from the specified commit' do
        result = command.call('old-branch', first_commit_sha)

        expect(result).to be_a(Git::BranchInfo)
        expect(result.refname).to eq('old-branch')

        # Verify the branch points to the first commit
        branch_sha = execution_context.command('rev-parse', 'old-branch').stdout.strip
        expect(branch_sha).to eq(first_commit_sha)
      end

      it 'creates a branch from an existing branch name' do
        result = command.call('feature-from-main', 'main')

        expect(result).to be_a(Git::BranchInfo)
        expect(result.refname).to eq('feature-from-main')
      end
    end

    context 'when creating a branch with special characters in name' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
      end

      it 'creates a branch with slashes' do
        result = command.call('feature/my-feature')

        expect(result).to be_a(Git::BranchInfo)
        expect(result.refname).to eq('feature/my-feature')
        expect(result.short_name).to eq('feature/my-feature')
      end

      it 'creates a branch with hyphens and underscores' do
        result = command.call('feature_with-mixed_chars')

        expect(result).to be_a(Git::BranchInfo)
        expect(result.refname).to eq('feature_with-mixed_chars')
      end
    end

    context 'when using the :force option' do
      let(:first_commit_sha) do
        write_file('file1.txt', 'content1')
        repo.add('file1.txt')
        repo.commit('First commit')
        execution_context.command('rev-parse', 'HEAD').stdout.strip
      end

      before do
        first_commit_sha
        write_file('file2.txt', 'content2')
        repo.add('file2.txt')
        repo.commit('Second commit')
        # Create a branch at HEAD (second commit)
        repo.branch('existing-branch').create
      end

      it 'resets an existing branch to a new start point' do
        # existing-branch currently points to second commit (HEAD)
        result = command.call('existing-branch', first_commit_sha, force: true)

        expect(result).to be_a(Git::BranchInfo)
        expect(result.refname).to eq('existing-branch')

        # Verify the branch now points to the first commit
        branch_sha = execution_context.command('rev-parse', 'existing-branch').stdout.strip
        expect(branch_sha).to eq(first_commit_sha)
      end
    end

    context 'when the branch already exists without force' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.branch('existing-branch').create
      end

      it 'raises an error' do
        expect { command.call('existing-branch') }.to raise_error(Git::FailedError)
      end
    end
  end
end
