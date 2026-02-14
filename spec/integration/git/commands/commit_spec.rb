# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/commit'

RSpec.describe Git::Commands::Commit, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    describe 'when the command succeeds' do
      before do
        write_file('file.txt', "content\n")
        repo.add('file.txt')
      end

      it 'returns a CommandLineResult' do
        result = command.call(message: 'Test commit')

        expect(result).to be_a(Git::CommandLineResult)
      end

      context 'with allow_empty option' do
        before { repo.commit('Initial commit') }

        it 'returns a CommandLineResult' do
          result = command.call(message: 'Empty commit', allow_empty: true)

          expect(result).to be_a(Git::CommandLineResult)
        end
      end
    end

    describe 'when the command fails' do
      before do
        write_file('file.txt', "content\n")
        repo.add('file.txt')
        repo.commit('Initial commit')
      end

      it 'raises FailedError with nothing staged' do
        expect { command.call(message: 'Empty') }.to raise_error(Git::FailedError)
      end
    end
  end
end
