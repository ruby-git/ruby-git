# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/list'

RSpec.describe Git::Commands::Branch::List, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when the command succeeds' do
      it 'returns a CommandLineResult with output after a commit' do
        write_file('file.txt')
        repo.add('file.txt')
        repo.commit('Initial commit')

        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).not_to be_empty
      end

      it 'returns empty output when there are no branches' do
        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).to be_empty
      end
    end

    context 'when the command fails' do
      it 'raises FailedError for an invalid sort key' do
        write_file('file.txt')
        repo.add('file.txt')
        repo.commit('Initial commit')

        # git includes the invalid field name in its error message
        expect { command.call(sort: 'invalid-key') }
          .to raise_error(Git::FailedError, /invalid-key/)
      end
    end
  end
end
