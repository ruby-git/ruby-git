# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/reset'

RSpec.describe Git::Commands::Reset, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('file.txt', "original\n")
    repo.add('file.txt')
    repo.commit('Initial commit')
  end

  describe '#call' do
    describe 'when the command succeeds' do
      before do
        write_file('file.txt', "modified\n")
        repo.add('file.txt')
      end

      it 'returns a CommandLineResult' do
        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
      end

      context 'with hard reset' do
        it 'returns a CommandLineResult' do
          result = command.call(hard: true)

          expect(result).to be_a(Git::CommandLineResult)
        end
      end
    end

    describe 'when the command fails' do
      it 'raises FailedError with an invalid ref' do
        expect { command.call('nonexistent-ref') }.to raise_error(Git::FailedError)
      end
    end
  end
end
