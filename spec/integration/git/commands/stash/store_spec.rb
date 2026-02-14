# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/store'

RSpec.describe Git::Commands::Stash::Store, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('file.txt', "content\n")
    repo.add('file.txt')
    repo.commit('Initial commit')
  end

  describe '#call' do
    describe 'when the command succeeds' do
      before { write_file('file.txt', "modified\n") }

      it 'returns a CommandLineResult' do
        sha = execution_context.command('stash', 'create').stdout.strip

        result = command.call(sha)

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    describe 'when the command fails' do
      it 'raises FailedError with an invalid commit SHA' do
        expect { command.call('0000000000000000000000000000000000000000') }.to raise_error(Git::FailedError)
      end
    end
  end
end
