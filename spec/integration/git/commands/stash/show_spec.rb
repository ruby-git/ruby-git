# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/show_numstat'
require 'git/commands/stash/show_patch'
require 'git/commands/stash/show_raw'

# Integration tests for git stash show commands.
#
# These tests verify that the commands work correctly with real git repositories.
# Focus on smoke tests and exit codes, not output format parsing.
#
RSpec.describe 'Git::Commands::Stash::Show*', :integration do
  include_context 'in an empty repository'

  before do
    # Create initial commit
    write_file('tracked.txt', "initial content\n")
    repo.add('tracked.txt')
    repo.commit('Initial commit')
  end

  describe Git::Commands::Stash::ShowNumstat do
    subject(:command) { described_class.new(execution_context) }

    context 'with a stash' do
      before do
        write_file('tracked.txt', "modified content\nmore lines\n")
        repo.lib.stash_save('WIP')
      end

      it 'returns CommandLineResult with output' do
        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.exitstatus).to eq(0)
        expect(result.stdout).not_to be_empty
      end
    end
  end

  describe Git::Commands::Stash::ShowPatch do
    subject(:command) { described_class.new(execution_context) }

    context 'with a stash' do
      before do
        write_file('tracked.txt', "modified content\nmore lines\n")
        repo.lib.stash_save('WIP')
      end

      it 'returns CommandLineResult with output' do
        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.exitstatus).to eq(0)
        expect(result.stdout).not_to be_empty
      end
    end
  end

  describe Git::Commands::Stash::ShowRaw do
    subject(:command) { described_class.new(execution_context) }

    context 'with a stash' do
      before do
        write_file('tracked.txt', "modified content\nmore lines\n")
        repo.lib.stash_save('WIP')
      end

      it 'returns CommandLineResult with output' do
        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.exitstatus).to eq(0)
        expect(result.stdout).not_to be_empty
      end
    end
  end
end
