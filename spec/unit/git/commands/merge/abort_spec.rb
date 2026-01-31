# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/merge/abort'

RSpec.describe Git::Commands::Merge::Abort do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '::ARGS' do
    it 'builds correct command arguments' do
      args = described_class::ARGS.build
      expect(args).to eq(['merge', '--abort'])
    end
  end

  describe '#initialize' do
    it 'stores the execution context' do
      expect(command.instance_variable_get(:@execution_context)).to eq(execution_context)
    end
  end

  describe '#call' do
    it 'calls git merge --abort' do
      expect(execution_context).to receive(:command).with('merge', '--abort')
      command.call
    end

    it 'returns the CommandLineResult' do
      mock_result = command_result('')
      expect(execution_context).to receive(:command).with('merge', '--abort').and_return(mock_result)
      result = command.call
      expect(result).to eq(mock_result)
    end
  end
end
