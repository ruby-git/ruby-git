# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/apply'

RSpec.describe Git::Commands::Stash::Apply, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    # Create initial commit
    write_file('file.txt', "initial content\n")
    repo.add('file.txt')
    repo.commit('Initial commit')
  end

  describe '#call' do
    describe 'when the command succeeds' do
      before do
        write_file('file.txt', "modified content\n")
        repo.lib.stash_save('WIP')
      end

      it 'returns a CommandLineResult with output' do
        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).not_to be_empty
      end
    end

    describe 'when the command fails' do
      it 'raises FailedError with nonexistent stash' do
        expect { command.call('stash@{99}') }.to raise_error(Git::FailedError)
      end
    end
  end
end
