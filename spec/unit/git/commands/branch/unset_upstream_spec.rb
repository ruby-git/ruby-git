# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/unset_upstream'

RSpec.describe Git::Commands::Branch::UnsetUpstream do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments (unset upstream for current branch)' do
      it 'runs branch --unset-upstream' do
        expect(execution_context).to receive(:command)
          .with('branch', '--unset-upstream')
          .and_return(command_result(''))

        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).to eq('')
      end
    end

    context 'with branch_name' do
      it 'runs branch --unset-upstream <branch>' do
        expect(execution_context).to receive(:command)
          .with('branch', '--unset-upstream', 'feature')
          .and_return(command_result(''))

        result = command.call('feature')

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with nil branch_name' do
      it 'runs branch --unset-upstream (nil is treated as not provided)' do
        expect(execution_context).to receive(:command)
          .with('branch', '--unset-upstream')
          .and_return(command_result(''))

        result = command.call(nil)

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unknown options' do
        expect { command.call(unknown: true) }.to raise_error(ArgumentError, /unknown/)
      end
    end
  end
end
