# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/list'

# Integration tests for Git::Commands::Stash::List
#
# These tests verify the command's execution behavior. Parsing logic is
# tested separately in spec/integration/git/stash_parser_spec.rb.
#
RSpec.describe Git::Commands::Stash::List, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
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

    context 'with stashes' do
      before do
        write_file('file.txt', 'modified content')
        repo.lib.stash_save('WIP on feature')
      end

      it 'returns an array of StashInfo objects' do
        result = command.call
        expect(result.size).to eq(1)
        expect(result.first).to be_a(Git::StashInfo)
      end
    end

    context 'with multiple stashes' do
      before do
        write_file('file.txt', 'first change')
        repo.lib.stash_save('First stash')

        write_file('file.txt', 'second change')
        repo.lib.stash_save('Second stash')

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
    end
  end
end
