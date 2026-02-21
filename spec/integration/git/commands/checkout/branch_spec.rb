# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/checkout/branch'

RSpec.describe Git::Commands::Checkout::Branch, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('file.txt', "content\n")
    repo.add('file.txt')
    repo.commit('Initial commit')
  end

  describe '#call' do
    describe 'when the command succeeds' do
      it 'returns a CommandLineResult when switching branches' do
        repo.branch('feature').create

        result = command.call('feature')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'returns a CommandLineResult when creating a new branch' do
        result = command.call(b: 'new-feature')

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    describe 'when the command fails' do
      it 'raises FailedError with a nonexistent branch' do
        expect { command.call('nonexistent') }.to raise_error(Git::FailedError)
      end
    end
  end
end
