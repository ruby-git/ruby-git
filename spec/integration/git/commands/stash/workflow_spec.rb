# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/create'
require 'git/commands/stash/store'
require 'git/commands/stash/list'
require 'git/commands/stash/drop'

# Integration tests for stash workflows that involve multiple commands working together.
#
RSpec.describe 'Stash workflows', :integration do
  include_context 'in an empty repository'

  before do
    # Create initial commit
    write_file('file.txt', "initial content\n")
    repo.add('file.txt')
    repo.commit('Initial commit')
  end

  describe 'Create + Store workflow' do
    # git stash create + git stash store is the plumbing equivalent of git stash push
    # This workflow is useful for scripting when you need more control over the stash

    let(:create_command) { Git::Commands::Stash::Create.new(execution_context) }
    let(:store_command) { Git::Commands::Stash::Store.new(execution_context) }
    let(:list_command) { Git::Commands::Stash::List.new(execution_context) }

    context 'with local changes' do
      before do
        write_file('file.txt', "modified content\n")
      end

      it 'creates a stash commit and stores it in the reflog' do
        # Step 1: Create a stash commit (does not update refs/stash)
        sha = create_command.call
        expect(sha).to match(/\A[0-9a-f]{40}\z/)

        # Verify stash list is still empty (create doesn't store)
        stashes = list_command.call
        expect(stashes).to be_empty

        # Step 2: Store the commit in the stash reflog
        store_command.call(sha, message: 'Manually stored stash')

        # Verify stash now appears in list
        stashes = list_command.call
        expect(stashes.size).to eq(1)
        expect(stashes.first.message).to eq('Manually stored stash')
        expect(stashes.first.oid).to eq(sha)
      end

      it 'creates a stash commit with a message' do
        sha = create_command.call('WIP: my changes')
        expect(sha).to match(/\A[0-9a-f]{40}\z/)

        # Store without custom message - git uses the create message
        store_command.call(sha)

        stashes = list_command.call
        expect(stashes.size).to eq(1)
      end

      it 'does not modify the working directory' do
        # Unlike stash push, create does not reset the working directory
        create_command.call

        content = read_file('file.txt')
        expect(content).to eq("modified content\n")
      end
    end

    context 'with no local changes' do
      it 'returns nil when nothing to stash' do
        sha = create_command.call
        expect(sha).to be_nil
      end
    end

    context 'storing multiple stashes' do
      it 'maintains correct stash order (newest first)' do
        # Create and store first stash
        write_file('file.txt', "first change\n")
        sha1 = create_command.call
        store_command.call(sha1, message: 'First stash')

        # Create and store second stash
        write_file('file.txt', "second change\n")
        sha2 = create_command.call
        store_command.call(sha2, message: 'Second stash')

        stashes = list_command.call
        expect(stashes.size).to eq(2)
        expect(stashes[0].message).to eq('Second stash')
        expect(stashes[0].index).to eq(0)
        expect(stashes[1].message).to eq('First stash')
        expect(stashes[1].index).to eq(1)
      end
    end
  end

  describe 'Drop workflow' do
    let(:drop_command) { Git::Commands::Stash::Drop.new(execution_context) }
    let(:list_command) { Git::Commands::Stash::List.new(execution_context) }

    context 'with multiple stashes' do
      before do
        write_file('file.txt', "first\n")
        repo.lib.stash_save('First')

        write_file('file.txt', "second\n")
        repo.lib.stash_save('Second')

        write_file('file.txt', "third\n")
        repo.lib.stash_save('Third')
      end

      it 'drops the latest stash by default' do
        stashes_before = list_command.call
        expect(stashes_before.size).to eq(3)
        expect(stashes_before[0].message).to include('Third')

        drop_command.call

        stashes_after = list_command.call
        expect(stashes_after.size).to eq(2)
        expect(stashes_after[0].message).to include('Second')
      end

      it 'drops a specific stash by index' do
        # Drop the middle stash (index 1 = "Second")
        drop_command.call('1')

        stashes_after = list_command.call
        expect(stashes_after.size).to eq(2)
        messages = stashes_after.map(&:message)
        expect(messages.any? { |m| m.include?('Third') }).to be true
        expect(messages.any? { |m| m.include?('First') }).to be true
        expect(messages.any? { |m| m.include?('Second') }).to be false
      end

      it 'returns the dropped stash info' do
        result = drop_command.call

        expect(result).to be_a(Git::StashInfo)
        expect(result.message).to include('Third')
      end
    end
  end
end
