# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/move'

RSpec.describe Git::Commands::Branch::Move, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when renaming the current branch' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
      end

      it 'renames the current branch to a new name' do
        result = command.call('main-renamed')

        expect(result).to be_a(Git::BranchInfo)
        expect(result.refname).to eq('main-renamed')
      end

      it 'removes the original branch' do
        command.call('main-renamed')

        branch_list = repo.branches.local.map(&:name)
        expect(branch_list).not_to include('main')
        expect(branch_list).to include('main-renamed')
      end

      it 'keeps the renamed branch as current' do
        result = command.call('main-renamed')

        expect(result.current?).to be true
      end

      it 'preserves the commit history' do
        original_sha = execution_context.command('rev-parse', 'main').stdout.strip
        command.call('main-renamed')
        renamed_sha = execution_context.command('rev-parse', 'main-renamed').stdout.strip

        expect(renamed_sha).to eq(original_sha)
      end
    end

    context 'when renaming a specific branch' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.branch('feature').create
      end

      it 'renames the specified branch' do
        result = command.call('feature', 'feature-renamed')

        expect(result).to be_a(Git::BranchInfo)
        expect(result.refname).to eq('feature-renamed')
      end

      it 'removes the original branch and creates the new one' do
        command.call('feature', 'feature-renamed')

        branch_list = repo.branches.local.map(&:name)
        expect(branch_list).not_to include('feature')
        expect(branch_list).to include('feature-renamed')
      end

      it 'does not change the current branch' do
        command.call('feature', 'feature-renamed')

        expect(repo.current_branch).to eq('main')
      end
    end

    context 'when using force option' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.branch('existing').create
        repo.branch('to-rename').create
      end

      it 'overwrites an existing branch with force' do
        result = command.call('to-rename', 'existing', force: true)

        expect(result).to be_a(Git::BranchInfo)
        expect(result.refname).to eq('existing')

        branch_list = repo.branches.local.map(&:name)
        expect(branch_list).not_to include('to-rename')
      end

      it 'raises an error without force when target exists' do
        expect { command.call('to-rename', 'existing') }.to raise_error(Git::FailedError)
      end
    end

    context 'with branch names containing special characters' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
      end

      it 'renames to a branch with slashes' do
        result = command.call('feature/renamed')

        expect(result).to be_a(Git::BranchInfo)
        expect(result.refname).to eq('feature/renamed')
      end
    end
  end
end
