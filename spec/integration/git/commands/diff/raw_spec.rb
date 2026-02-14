# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/diff/raw'

RSpec.describe Git::Commands::Diff::Raw, :integration do
  include_context 'in a diff test repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    describe 'when the command succeeds' do
      it 'returns a CommandLineResult with output' do
        result = command.call('initial', 'after_modify')

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).not_to be_empty
      end

      it 'returns exit code 0 with no differences' do
        result = command.call('initial', 'initial')

        expect(result.status.exitstatus).to eq(0)
        expect(result.stdout).to be_empty
      end

      it 'succeeds with differences found' do
        result = command.call('initial', 'after_modify')

        expect(result.status.exitstatus).to be <= 1
        expect(result.stdout).not_to be_empty
      end
    end

    describe 'when the command fails' do
      it 'raises FailedError for invalid revision' do
        expect { command.call('nonexistent-ref') }.to raise_error(Git::FailedError)
      end
    end
  end
end
