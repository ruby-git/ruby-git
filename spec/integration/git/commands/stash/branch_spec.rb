# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/branch'

RSpec.describe Git::Commands::Stash::Branch, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when creating a branch from a stash' do
      before do
        # Create initial commit
        write_file('file.txt', 'initial content')
        repo.add('file.txt')
        repo.commit('Initial commit')

        # Create changes and stash them
        write_file('file.txt', 'modified content')
        repo.lib.stash_save('WIP changes')
      end

      it 'creates the branch and returns BranchInfo' do
        result = command.call('stash-branch')

        expect(result).to be_a(Git::BranchInfo)
        expect(result.refname).to eq('stash-branch')
      end

      it 'creates a local branch' do
        result = command.call('stash-branch')

        expect(result.remote?).to be false
      end

      it 'switches to the new branch (makes it current)' do
        result = command.call('stash-branch')

        expect(result.current?).to be true
      end

      it 'applies the stashed changes to the working directory' do
        command.call('stash-branch')

        content = read_file('file.txt')
        expect(content).to eq('modified content')
      end

      it 'drops the stash after successful application' do
        command.call('stash-branch')

        stashes = repo.lib.stashes_list
        expect(stashes).to be_empty
      end

      it 'makes the branch visible in the repository' do
        command.call('stash-branch')

        branch_names = repo.branches.local.map(&:name)
        expect(branch_names).to include('stash-branch')
      end
    end

    context 'when creating a branch from a specific stash' do
      before do
        # Create initial commit
        write_file('file.txt', 'initial content')
        repo.add('file.txt')
        repo.commit('Initial commit')

        # Create first stash
        write_file('file.txt', 'first stash content')
        repo.lib.stash_save('First stash')

        # Create second stash
        write_file('file.txt', 'second stash content')
        repo.lib.stash_save('Second stash')
      end

      it 'creates branch from the specified stash' do
        # stash@{1} is the first stash (older one)
        result = command.call('from-first-stash', 'stash@{1}')

        expect(result).to be_a(Git::BranchInfo)
        expect(result.refname).to eq('from-first-stash')

        content = read_file('file.txt')
        expect(content).to eq('first stash content')
      end

      it 'accepts numeric stash index' do
        result = command.call('from-second-stash', '0')

        expect(result).to be_a(Git::BranchInfo)

        content = read_file('file.txt')
        expect(content).to eq('second stash content')
      end
    end

    context 'when branch name already exists' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')

        # Create the branch first
        repo.branch('existing-branch').create

        # Then create a stash
        write_file('file.txt', 'stashed content')
        repo.lib.stash_save('WIP')
      end

      it 'raises FailedError' do
        expect { command.call('existing-branch') }.to raise_error(Git::FailedError) do |error|
          expect(error.message).to include('existing-branch')
          expect(error.message).to include('already exists')
        end
      end
    end

    context 'when stash does not exist' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        # No stash created
      end

      it 'raises FailedError' do
        expect { command.call('new-branch') }.to raise_error(Git::FailedError)
      end
    end

    context 'with branch names containing special characters' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')

        write_file('file.txt', 'stashed')
        repo.lib.stash_save('WIP')
      end

      it 'handles branch names with slashes' do
        result = command.call('feature/from-stash')

        expect(result).to be_a(Git::BranchInfo)
        expect(result.refname).to eq('feature/from-stash')
      end

      it 'handles branch names with hyphens' do
        result = command.call('fix-from-stash-123')

        expect(result).to be_a(Git::BranchInfo)
        expect(result.refname).to eq('fix-from-stash-123')
      end
    end
  end
end
