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

    context 'with local changes' do
      before do
        write_file('file.txt', "modified content\n")
      end

      it 'creates a stash commit SHA that can be stored' do
        create_result = create_command.call
        expect(create_result).to be_a(Git::CommandLineResult)

        sha = create_result.stdout.strip
        expect(sha).to match(/\A[0-9a-f]{40}\z/)

        store_result = store_command.call(sha)
        expect(store_result).to be_a(Git::CommandLineResult)
        expect(store_result.status.exitstatus).to eq(0)
      end
    end

    context 'with no local changes' do
      it 'returns a CommandLineResult with empty output' do
        result = create_command.call
        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout.strip).to be_empty
      end
    end
  end

  describe 'Drop workflow' do
    let(:drop_command) { Git::Commands::Stash::Drop.new(execution_context) }

    context 'with a stash' do
      before do
        write_file('file.txt', "modified\n")
        repo.lib.stash_save('WIP')
      end

      it 'returns a CommandLineResult with output' do
        result = drop_command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).not_to be_empty
      end
    end
  end
end
