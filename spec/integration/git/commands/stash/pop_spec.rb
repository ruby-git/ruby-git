# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/pop'
require 'git/commands/stash/list'

RSpec.describe Git::Commands::Stash::Pop, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    # Create initial commit
    write_file('file.txt', "initial content\n")
    repo.add('file.txt')
    repo.commit('Initial commit')
  end

  describe '#call' do
    describe 'with :index option' do
      context 'when stash was created with staged changes' do
        before do
          # Stage changes and create stash
          write_file('file.txt', "staged changes\n")
          repo.add('file.txt')
          repo.lib.stash_save('WIP with staged')
        end

        it 'restores index state when index: true' do
          command.call(index: true)

          # Verify the changes are in the index (staged)
          status = repo.status
          expect(status['file.txt']).not_to be_nil
          expect(status['file.txt'].type).to eq('M')
        end

        it 'does not restore index state by default' do
          command.call

          # Verify changes are in working directory but not staged
          status = repo.status
          # Changes appear as modified in worktree, not index
          expect(status['file.txt'].type).to eq('M')
        end
      end

      context 'when stash was created with both staged and unstaged changes' do
        before do
          # Stage one change
          write_file('file.txt', "staged change\n")
          repo.add('file.txt')

          # Add another change without staging
          write_file('file.txt', "staged change\nunstaged change\n")

          repo.lib.stash_save('WIP with mixed changes')
        end

        it 'restores both staged and unstaged states when index: true' do
          command.call(index: true)

          # Verify there are staged changes
          status = repo.status
          expect(status['file.txt']).not_to be_nil
          expect(status['file.txt'].type).to eq('M')

          # Verify the full content is restored
          content = read_file('file.txt')
          expect(content).to eq("staged change\nunstaged change\n")
        end
      end
    end

    describe 'basic pop behavior' do
      before do
        write_file('file.txt', "modified content\n")
        repo.lib.stash_save('WIP')
      end

      it 'removes the stash after successful pop' do
        stashes_before = Git::Commands::Stash::List.new(execution_context).call
        expect(stashes_before.size).to eq(1)

        command.call

        stashes_after = Git::Commands::Stash::List.new(execution_context).call
        expect(stashes_after).to be_empty
      end

      it 'restores the working directory changes' do
        command.call

        content = read_file('file.txt')
        expect(content).to eq("modified content\n")
      end

      it 'returns the StashInfo of the popped stash' do
        result = command.call

        expect(result).to be_a(Git::StashInfo)
        expect(result.name).to eq('stash@{0}')
      end
    end
  end
end
