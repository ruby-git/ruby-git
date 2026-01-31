# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/list'

# Integration tests for Git::Commands::Stash::List
#
# These tests verify that the command's custom format string produces output
# that matches our parsing expectations. This is essential since unit tests
# mock this output.
#
RSpec.describe Git::Commands::Stash::List, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    # Create initial commit
    write_file('file.txt', 'initial content')
    repo.add('file.txt')
    repo.commit('Initial commit')
  end

  describe '#call' do
    context 'with no stashes' do
      it 'returns an empty array' do
        result = command.call

        expect(result).to eq([])
      end
    end

    context 'with a single stash' do
      before do
        write_file('file.txt', 'modified content')
        repo.lib.stash_save('WIP on feature')
      end

      it 'returns an array with one StashInfo' do
        result = command.call

        expect(result.size).to eq(1)
        expect(result.first).to be_a(Git::StashInfo)
      end

      it 'parses the stash index correctly' do
        result = command.call

        expect(result.first.index).to eq(0)
      end

      it 'parses the stash name correctly' do
        result = command.call

        expect(result.first.name).to eq('stash@{0}')
      end

      it 'parses the OID fields (verifies format string produces valid SHA)' do
        result = command.call

        expect(result.first.oid).to match(/\A[0-9a-f]{40}\z/)
        expect(result.first.short_oid).to match(/\A[0-9a-f]{7,}\z/)
      end

      it 'parses the message correctly' do
        result = command.call

        # Message includes the branch info from git
        expect(result.first.message).to include('WIP on feature')
      end

      it 'parses author information (verifies format string includes author)' do
        result = command.call

        expect(result.first.author_name).to be_a(String)
        expect(result.first.author_name).not_to be_empty
        expect(result.first.author_email).to match(/@/)
        expect(result.first.author_date).to be_a(String)
      end

      it 'parses committer information (verifies format string includes committer)' do
        result = command.call

        expect(result.first.committer_name).to be_a(String)
        expect(result.first.committer_name).not_to be_empty
        expect(result.first.committer_email).to match(/@/)
        expect(result.first.committer_date).to be_a(String)
      end
    end

    context 'with multiple stashes' do
      before do
        # Create first stash
        write_file('file.txt', 'first change')
        repo.lib.stash_save('First stash')

        # Create second stash
        write_file('file.txt', 'second change')
        repo.lib.stash_save('Second stash')

        # Create third stash
        write_file('file.txt', 'third change')
        repo.lib.stash_save('Third stash')
      end

      it 'returns stashes in order (newest first)' do
        result = command.call

        expect(result.size).to eq(3)
        expect(result[0].index).to eq(0)
        expect(result[1].index).to eq(1)
        expect(result[2].index).to eq(2)
      end

      it 'assigns correct names to each stash' do
        result = command.call

        expect(result[0].name).to eq('stash@{0}')
        expect(result[1].name).to eq('stash@{1}')
        expect(result[2].name).to eq('stash@{2}')
      end

      it 'preserves distinct messages for each stash' do
        result = command.call

        messages = result.map(&:message)
        expect(messages[0]).to include('Third stash')
        expect(messages[1]).to include('Second stash')
        expect(messages[2]).to include('First stash')
      end

      it 'assigns unique OIDs to each stash' do
        result = command.call

        oids = result.map(&:oid)
        expect(oids.uniq.size).to eq(3)
      end
    end

    context 'with custom message format (no branch prefix)' do
      before do
        # Create a stash using create + store to have a custom message
        write_file('file.txt', 'modified')
        result = repo.lib.command('stash', 'create', 'Custom message')
        sha = result.is_a?(String) ? result.strip : result.stdout.strip
        repo.lib.command('stash', 'store', '--message=custom: my message', sha)
      end

      it 'parses custom message correctly' do
        result = command.call

        # Custom messages don't have the "WIP on branch:" prefix
        expect(result.first.message).to eq('custom: my message')
        # Branch should be nil for custom messages without branch info
        expect(result.first.branch).to be_nil
      end
    end
  end
end
