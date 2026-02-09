# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/branch'

RSpec.describe Git::Commands::Stash::Branch, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    before do
      # Create initial commit
      write_file('file.txt', 'initial content')
      repo.add('file.txt')
      repo.commit('Initial commit')

      # Create changes and stash them
      write_file('file.txt', 'modified content')
      repo.lib.stash_save('WIP changes')
    end

    it 'returns a CommandLineResult with output' do
      result = command.call('stash-branch')

      expect(result).to be_a(Git::CommandLineResult)
      expect(result.stdout).not_to be_empty
    end

    context 'with nonexistent stash' do
      it 'raises FailedError' do
        expect { command.call('new-branch', 'stash@{99}') }.to raise_error(Git::FailedError)
      end
    end

    context 'with existing branch name' do
      it 'raises FailedError' do
        repo.branch('existing-branch').create

        expect { command.call('existing-branch') }.to raise_error(Git::FailedError)
      end
    end
  end
end
