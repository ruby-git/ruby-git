# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/push'
require 'git/commands/stash/list'

RSpec.describe Git::Commands::Stash::Push, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    # Create initial commit
    write_file('tracked.txt', "initial content\n")
    repo.add('tracked.txt')
    repo.commit('Initial commit')
  end

  describe '#call' do
    describe 'with :keep_index option' do
      before do
        # Modify and stage a file
        write_file('tracked.txt', "staged changes\n")
        repo.add('tracked.txt')
      end

      it 'preserves staged changes in the index when keep_index: true' do
        command.call(keep_index: true)

        # Verify the stash was created
        stashes = Git::Commands::Stash::List.new(execution_context).call
        expect(stashes.size).to eq(1)

        # Verify staged changes are still in the index
        status = repo.status
        expect(status['tracked.txt']).not_to be_nil
        expect(status['tracked.txt'].type).to eq('M')
      end

      it 'removes staged changes from index when keep_index: false' do
        command.call(keep_index: false)

        # Verify the stash was created
        stashes = Git::Commands::Stash::List.new(execution_context).call
        expect(stashes.size).to eq(1)

        # Verify staged changes were removed from the index (file is clean)
        status = repo.status
        expect(status.changed?('tracked.txt')).to be false
      end

      it 'removes staged changes from index by default (no keep_index option)' do
        command.call

        # Verify staged changes were removed from the index (file is clean)
        status = repo.status
        expect(status.changed?('tracked.txt')).to be false
      end
    end

    describe 'with :staged option' do
      before do
        # Stage one file
        write_file('staged.txt', "staged content\n")
        repo.add('staged.txt')

        # Modify another file without staging
        write_file('tracked.txt', "unstaged changes\n")
      end

      it 'stashes only staged changes when staged: true' do
        command.call(staged: true)

        # Verify the stash was created
        stashes = Git::Commands::Stash::List.new(execution_context).call
        expect(stashes.size).to eq(1)

        # Verify staged file is no longer staged (stashed away)
        status = repo.status
        expect(status['staged.txt']).to be_nil

        # Verify unstaged changes remain in working directory
        content = read_file('tracked.txt')
        expect(content).to eq("unstaged changes\n")
      end

      it 'stashes all changes by default (without staged option)' do
        command.call

        # Verify both changes were stashed (files are clean)
        status = repo.status
        expect(status.changed?('staged.txt')).to be false
        expect(status.changed?('tracked.txt')).to be false

        # Working directory should be clean
        content = read_file('tracked.txt')
        expect(content).to eq("initial content\n")
      end
    end

    describe 'with :include_untracked option' do
      before do
        # Create an untracked file
        write_file('untracked.txt', "untracked content\n")
        # Modify tracked file
        write_file('tracked.txt', "modified\n")
      end

      it 'includes untracked files when include_untracked: true' do
        command.call(include_untracked: true)

        # Verify the stash was created
        stashes = Git::Commands::Stash::List.new(execution_context).call
        expect(stashes.size).to eq(1)

        # Verify untracked file was removed (stashed)
        expect(file_exist?('untracked.txt')).to be false
      end

      it 'leaves untracked files by default' do
        command.call

        # Verify the stash was created
        stashes = Git::Commands::Stash::List.new(execution_context).call
        expect(stashes.size).to eq(1)

        # Verify untracked file still exists
        expect(file_exist?('untracked.txt')).to be true
        content = read_file('untracked.txt')
        expect(content).to eq("untracked content\n")
      end
    end

    describe 'with pathspecs' do
      before do
        # Modify multiple files
        write_file('tracked.txt', "modified tracked\n")
        write_file('other.txt', "other content\n")
        repo.add('other.txt')
        repo.commit('Add other.txt')
        write_file('other.txt', "modified other\n")
      end

      it 'stashes only specified paths' do
        command.call('tracked.txt')

        # Verify the stash was created
        stashes = Git::Commands::Stash::List.new(execution_context).call
        expect(stashes.size).to eq(1)

        # Verify tracked.txt was stashed (reverted)
        content = read_file('tracked.txt')
        expect(content).to eq("initial content\n")

        # Verify other.txt was NOT stashed (still modified)
        other_content = read_file('other.txt')
        expect(other_content).to eq("modified other\n")
      end
    end
  end
end
