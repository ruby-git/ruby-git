# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/checkout_index'

RSpec.describe Git::Commands::CheckoutIndex, :integration do
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
        result = command.call(all: true)

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'returns a CommandLineResult with force option' do
        result = command.call(all: true, force: true)

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'returns a CommandLineResult for a specific file' do
        result = command.call('file.txt')

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    describe 'when the command fails' do
      it 'raises FailedError for a nonexistent file path' do
        expect { command.call('nonexistent.txt') }.to raise_error(Git::FailedError)
      end
    end

    describe 'input validation' do
      it 'raises ArgumentError when :all and a file path are both given' do
        expect { command.call('file.txt', all: true) }.to(
          raise_error(ArgumentError, /cannot specify :all and :file/)
        )
      end

      it 'raises ArgumentError for an invalid :stage value' do
        expect { command.call(stage: 'invalid') }.to(
          raise_error(ArgumentError, /Invalid value for :stage/)
        )
      end
    end
  end
end
