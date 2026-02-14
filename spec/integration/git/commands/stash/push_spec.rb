# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/push'

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
    describe 'when the command succeeds' do
      context 'with changes to stash' do
        before do
          write_file('tracked.txt', "modified content\n")
        end

        it 'returns a CommandLineResult with output' do
          result = command.call

          expect(result).to be_a(Git::CommandLineResult)
          expect(result.stdout).not_to be_empty
        end
      end

      context 'with no changes' do
        it 'returns a CommandLineResult' do
          result = command.call

          expect(result).to be_a(Git::CommandLineResult)
          expect(result.stdout).not_to be_empty
        end
      end
    end

    describe 'when the command fails' do
      before { write_file('tracked.txt', "modified content\n") }

      it 'raises FailedError with a nonexistent pathspec' do
        expect { command.call('nonexistent.txt') }.to raise_error(Git::FailedError)
      end
    end
  end
end
