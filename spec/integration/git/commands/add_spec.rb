# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/add'

RSpec.describe Git::Commands::Add, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('file.txt', "content\n")
    repo.add('file.txt')
    repo.commit('Initial commit')
  end

  describe '#call' do
    describe 'when the command succeeds' do
      context 'with a new file' do
        before { write_file('new.txt', "new content\n") }

        it 'returns a CommandLineResult' do
          result = command.call('new.txt')

          expect(result).to be_a(Git::CommandLineResult)
        end
      end

      context 'with the all option' do
        before { write_file('file.txt', "modified\n") }

        it 'returns a CommandLineResult' do
          result = command.call(all: true)

          expect(result).to be_a(Git::CommandLineResult)
        end
      end
    end

    describe 'when the command fails' do
      it 'raises FailedError with a nonexistent path' do
        expect { command.call('nonexistent.txt') }.to raise_error(Git::FailedError)
      end

      it 'raises ArgumentError when pathspec_file_nul is given without pathspec_from_file' do
        expect { command.call(pathspec_file_nul: true) }
          .to raise_error(ArgumentError, /:pathspec_file_nul requires :pathspec_from_file/)
      end

      it 'raises ArgumentError when ignore_missing is given without dry_run' do
        expect { command.call(ignore_missing: true) }
          .to raise_error(ArgumentError, /:ignore_missing requires :dry_run/)
      end
    end
  end
end
