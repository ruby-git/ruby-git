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

        expect(result).to be_a(Git::CommandLine::Result)
      end
    end

    describe 'when the command fails' do
      # git checkout-index only exits non-zero for a missing path starting in 2.30.0; on
      # 2.28.0-2.29.x it warns on stderr but exits 0.
      it 'raises FailedError for a nonexistent file path',
         skip: unless_git('2.30.0', 'git checkout-index exit status for a nonexistent path') do
        expect { command.call('nonexistent.txt') }.to raise_error(Git::FailedError)
      end
    end
  end
end
