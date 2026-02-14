# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/rm'

RSpec.describe Git::Commands::Rm, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('file.txt', "content\n")
    repo.add('file.txt')
    repo.commit('Initial commit')
  end

  describe '#call' do
    describe 'when the command succeeds' do
      it 'returns a CommandLineResult' do
        result = command.call('file.txt')

        expect(result).to be_a(Git::CommandLineResult)
      end

      context 'with cached option' do
        it 'returns a CommandLineResult' do
          result = command.call('file.txt', cached: true)

          expect(result).to be_a(Git::CommandLineResult)
        end
      end
    end

    describe 'when the command fails' do
      it 'raises FailedError with a nonexistent file' do
        expect { command.call('nonexistent.txt') }.to raise_error(Git::FailedError)
      end
    end
  end
end
