# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/tag/delete'

RSpec.describe Git::Commands::Tag::Delete, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    before do
      write_file('file.txt', 'content')
      repo.add('file.txt')
      repo.commit('Initial commit')
      repo.add_tag('v1.0.0')
    end

    describe 'when the command succeeds' do
      it 'returns a CommandLineResult with output' do
        result = command.call('v1.0.0')

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).not_to be_empty
      end

      it 'returns exit code 0 when all tags are deleted' do
        result = command.call('v1.0.0')

        expect(result.status.exitstatus).to eq(0)
      end

      it 'returns exit code 1 for partial failure' do
        repo.add_tag('v2.0.0')

        result = command.call('v1.0.0', 'nonexistent', 'v2.0.0')

        expect(result.status.exitstatus).to eq(1)
        expect(result.stdout).not_to be_empty
      end
    end

    describe 'when the command fails' do
      it 'raises ArgumentError for option-like tag names' do
        # Option-like operand validation rejects values starting with '-'
        # before they reach git, preventing misinterpretation as flags
        expect { command.call('--invalid-flag-xyz') }.to raise_error(ArgumentError, /option-like values/)
      end
    end
  end
end
