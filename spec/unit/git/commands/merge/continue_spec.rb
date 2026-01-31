# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/merge/continue'

RSpec.describe Git::Commands::Merge::Continue do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '::ARGS' do
    it 'builds correct command arguments' do
      args = described_class::ARGS.build
      expect(args).to eq(['merge', '--continue'])
    end
  end

  describe '#initialize' do
    it 'stores the execution context' do
      expect(command.instance_variable_get(:@execution_context)).to eq(execution_context)
    end
  end

  describe '#call' do
    it 'calls git merge --continue' do
      expect(execution_context).to receive(:command).with('merge', '--continue')
      command.call
    end

    it 'returns the CommandLineResult' do
      mock_result = command_result('[main abc123] Merge branch feature')
      expect(execution_context).to receive(:command).with('merge', '--continue').and_return(mock_result)
      result = command.call
      expect(result).to eq(mock_result)
    end
  end
end
