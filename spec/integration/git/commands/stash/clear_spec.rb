# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/clear'
require 'git/commands/stash/list'

RSpec.describe Git::Commands::Stash::Clear, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    # Create initial commit
    write_file('file.txt', "initial content\n")
    repo.add('file.txt')
    repo.commit('Initial commit')
  end

  describe '#call' do
    context 'with multiple stashes' do
      before do
        # Create three stashes
        write_file('file.txt', "first change\n")
        repo.lib.stash_save('First stash')

        write_file('file.txt', "second change\n")
        repo.lib.stash_save('Second stash')

        write_file('file.txt', "third change\n")
        repo.lib.stash_save('Third stash')
      end

      it 'removes all stash entries' do
        stashes_before = Git::Commands::Stash::List.new(execution_context).call
        expect(stashes_before.size).to eq(3)

        command.call

        stashes_after = Git::Commands::Stash::List.new(execution_context).call
        expect(stashes_after).to be_empty
      end
    end

    context 'with a single stash' do
      before do
        write_file('file.txt', "modified\n")
        repo.lib.stash_save('WIP')
      end

      it 'removes the stash' do
        stashes_before = Git::Commands::Stash::List.new(execution_context).call
        expect(stashes_before.size).to eq(1)

        command.call

        stashes_after = Git::Commands::Stash::List.new(execution_context).call
        expect(stashes_after).to be_empty
      end
    end

    context 'with no stashes' do
      it 'succeeds without error' do
        stashes_before = Git::Commands::Stash::List.new(execution_context).call
        expect(stashes_before).to be_empty

        expect { command.call }.not_to raise_error

        stashes_after = Git::Commands::Stash::List.new(execution_context).call
        expect(stashes_after).to be_empty
      end
    end
  end
end
