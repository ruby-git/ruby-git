# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/create'

RSpec.describe Git::Commands::Stash::Create do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments' do
      it 'runs stash create' do
        expect(execution_context).to receive(:command)
          .with('stash', 'create')
          .and_return(command_result("abc123def456789\n"))

        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).to eq("abc123def456789\n")
      end
    end

    context 'with message' do
      it 'passes message to command' do
        expect(execution_context).to receive(:command)
          .with('stash', 'create', 'WIP: my changes')
          .and_return(command_result("abc123\n"))

        command.call('WIP: my changes')
      end

      it 'handles message with special characters' do
        expect(execution_context).to receive(:command)
          .with('stash', 'create', 'Fix "bug" in code')
          .and_return(command_result("abc123\n"))

        command.call('Fix "bug" in code')
      end

      it 'handles empty string message' do
        expect(execution_context).to receive(:command)
          .with('stash', 'create', '')
          .and_return(command_result("abc123\n"))

        command.call('')
      end
    end

    context 'with nil message' do
      it 'omits nil message from arguments' do
        expect(execution_context).to receive(:command)
          .with('stash', 'create')
          .and_return(command_result("abc123\n"))

        command.call(nil)
      end
    end
  end
end
