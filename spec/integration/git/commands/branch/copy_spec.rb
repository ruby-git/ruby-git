# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/copy'

RSpec.describe Git::Commands::Branch::Copy, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when copying the current branch' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
      end

      it 'copies the current branch to a new name' do
        result = command.call('main-copy')

        expect(result).to be_a(Git::BranchInfo)
        expect(result.refname).to eq('main-copy')
      end

      it 'preserves the original branch' do
        command.call('main-copy')

        branch_list = repo.branches.local.map(&:name)
        expect(branch_list).to include('main', 'main-copy')
      end

      it 'keeps the original branch as current' do
        result = command.call('main-copy')

        expect(result.current?).to be false
        expect(repo.current_branch).to eq('main')
      end

      it 'creates a branch pointing to the same commit' do
        original_sha = execution_context.command('rev-parse', 'main').stdout.strip
        command.call('main-copy')
        copy_sha = execution_context.command('rev-parse', 'main-copy').stdout.strip

        expect(copy_sha).to eq(original_sha)
      end
    end

    context 'when copying a specific branch' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.branch('feature').create
        repo.branch('feature').checkout
        write_file('feature.txt', 'feature content')
        repo.add('feature.txt')
        repo.commit('Feature commit')
        repo.checkout('main')
      end

      it 'copies the specified branch to a new name' do
        result = command.call('feature', 'feature-copy')

        expect(result).to be_a(Git::BranchInfo)
        expect(result.refname).to eq('feature-copy')
      end

      it 'creates a branch pointing to the same commit as the source' do
        source_sha = execution_context.command('rev-parse', 'feature').stdout.strip
        command.call('feature', 'feature-copy')
        copy_sha = execution_context.command('rev-parse', 'feature-copy').stdout.strip

        expect(copy_sha).to eq(source_sha)
      end
    end

    context 'when using force option' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.branch('existing').create
      end

      it 'overwrites an existing branch with force' do
        result = command.call('existing', force: true)

        expect(result).to be_a(Git::BranchInfo)
        expect(result.refname).to eq('existing')
      end

      it 'raises an error without force when target exists' do
        expect { command.call('existing') }.to raise_error(Git::FailedError)
      end
    end

    context 'with branch names containing special characters' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
      end

      it 'copies to a branch with slashes' do
        result = command.call('feature/copied')

        expect(result).to be_a(Git::BranchInfo)
        expect(result.refname).to eq('feature/copied')
      end
    end
  end
end
