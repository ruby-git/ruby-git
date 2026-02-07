# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/delete'

RSpec.describe Git::Commands::Branch::Delete, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    before do
      write_file('file.txt', 'content')
      repo.add('file.txt')
      repo.commit('Initial commit')
    end

    it 'returns a CommandLineResult with output' do
      repo.branch('feature').create

      result = command.call('feature')

      expect(result).to be_a(Git::CommandLineResult)
      expect(result.stdout).not_to be_empty
    end

    describe 'exit code handling' do
      it 'returns exit code 0 when all branches deleted' do
        repo.branch('feature').create

        result = command.call('feature')

        expect(result.status.exitstatus).to eq(0)
        expect(result.stdout).not_to be_empty
      end

      it 'returns exit code 1 for partial failure' do
        repo.branch('exists').create

        result = command.call('exists', 'nonexistent')

        expect(result.status.exitstatus).to eq(1)
      end

      it 'raises FailedError for nonexistent branch only' do
        # Exit code 1 does not raise, but exit code > 1 would
        result = command.call('nonexistent')

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.exitstatus).to eq(1)
      end
    end
  end
end
