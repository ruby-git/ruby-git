# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/diff_index'

RSpec.describe Git::Commands::DiffIndex, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('file.txt', "initial content\n")
    repo.add('.')
    repo.commit('Initial commit')
  end

  describe '#call' do
    context 'when the command succeeds' do
      it 'returns a CommandLineResult with exit code 0 when no working-tree changes exist' do
        result = command.call('HEAD')
        expect(result).to be_a(Git::CommandLine::Result)
        expect(result.status.exitstatus).to eq(0)
      end

      it 'exits with status 1 when staged changes are present and --exit-code is given' do
        write_file('file.txt', "changed\n")
        repo.add('file.txt')
        result = command.call('HEAD', cached: true, exit_code: true)
        expect(result.status.exitstatus).to eq(1)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError for an invalid tree-ish' do
        expect { command.call('nonexistent-sha-deadbeef') }
          .to raise_error(Git::FailedError, /nonexistent-sha-deadbeef/)
      end
    end
  end
end
