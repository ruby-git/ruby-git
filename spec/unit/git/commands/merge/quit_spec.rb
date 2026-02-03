# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/merge/quit'

RSpec.describe Git::Commands::Merge::Quit do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '::ARGS' do
    it 'builds correct command arguments' do
      args = described_class::ARGS.bind.to_ary
      expect(args).to eq(['merge', '--quit'])
    end
  end

  describe '#initialize' do
    it 'stores the execution context' do
      expect(command.instance_variable_get(:@execution_context)).to eq(execution_context)
    end
  end

  describe '#call' do
    it 'calls git merge --quit' do
      expect(execution_context).to receive(:command).with('merge', '--quit')
      command.call
    end

    it 'returns the CommandLineResult' do
      mock_result = command_result('')
      expect(execution_context).to receive(:command).with('merge', '--quit').and_return(mock_result)
      result = command.call
      expect(result).to eq(mock_result)
    end
  end
end
