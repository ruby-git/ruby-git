# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/mv'

RSpec.describe Git::Commands::Mv, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('original.txt', "content\n")
    repo.add('original.txt')
    repo.commit('Initial commit')
  end

  describe '#call' do
    describe 'when the command succeeds' do
      it 'returns a CommandLineResult' do
        result = command.call('original.txt', 'renamed.txt')

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    describe 'when the command fails' do
      it 'raises FailedError with a nonexistent source' do
        expect { command.call('nonexistent.txt', 'dest.txt') }.to raise_error(Git::FailedError)
      end
    end
  end
end
