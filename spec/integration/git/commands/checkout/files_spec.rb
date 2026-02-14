# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/checkout/files'

RSpec.describe Git::Commands::Checkout::Files, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('file.txt', "original\n")
    repo.add('file.txt')
    repo.commit('Initial commit')
  end

  describe '#call' do
    describe 'when the command succeeds' do
      before { write_file('file.txt', "modified\n") }

      it 'returns a CommandLineResult' do
        result = command.call('HEAD', 'file.txt')

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    describe 'when the command fails' do
      it 'raises FailedError with a nonexistent ref' do
        expect { command.call('nonexistent', 'file.txt') }.to raise_error(Git::FailedError)
      end
    end
  end
end
