# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/symbolic_ref/delete'

RSpec.describe Git::Commands::SymbolicRef::Delete, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when the command succeeds' do
      it 'deletes the symbolic ref' do
        # Create a custom symbolic ref to delete (not HEAD, which would break the repo)
        execution_context.command_capturing('symbolic-ref', 'refs/heads/sym-link', 'refs/heads/main')

        result = command.call('refs/heads/sym-link')

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.exitstatus).to eq(0)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError for a nonexistent ref' do
        expect { command.call('refs/heads/nonexistent') }
          .to raise_error(Git::FailedError, /nonexistent/)
      end
    end
  end
end
