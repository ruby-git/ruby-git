# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/clean'

RSpec.describe Git::Commands::Clean, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('tracked.txt', "content\n")
    repo.add('tracked.txt')
    repo.commit('Initial commit')
  end

  describe '#call' do
    describe 'when the command succeeds' do
      context 'with untracked files' do
        before { write_file('untracked.txt', "untracked\n") }

        it 'returns a CommandLineResult' do
          result = command.call(force: true)

          expect(result).to be_a(Git::CommandLineResult)
        end
      end

      context 'with untracked directories' do
        before do
          write_file('subdir/untracked.txt', "content\n")
        end

        it 'returns a CommandLineResult' do
          result = command.call(force: true, d: true)

          expect(result).to be_a(Git::CommandLineResult)
        end
      end
    end

    describe 'when the command fails' do
      before { write_file('untracked.txt', "untracked\n") }

      it 'raises FailedError without force flag' do
        expect { command.call }.to raise_error(Git::FailedError)
      end
    end
  end
end
