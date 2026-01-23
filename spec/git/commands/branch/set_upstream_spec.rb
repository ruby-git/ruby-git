# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/set_upstream'

RSpec.describe Git::Commands::Branch::SetUpstream do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with only set_upstream_to (set upstream for current branch)' do
      it 'calls git branch --set-upstream-to=<upstream>' do
        expect(execution_context).to receive(:command).with('branch', '--set-upstream-to=origin/main')
        command.call(set_upstream_to: 'origin/main')
      end
    end

    context 'with set_upstream_to and branch_name' do
      it 'calls git branch --set-upstream-to=<upstream> <branch>' do
        expect(execution_context).to receive(:command).with('branch', '--set-upstream-to=origin/main', 'feature')
        command.call('feature', set_upstream_to: 'origin/main')
      end
    end

    context 'with remote-tracking branch as upstream' do
      it 'accepts various remote-tracking branch formats' do
        expect(execution_context).to receive(:command).with('branch', '--set-upstream-to=upstream/develop')
        command.call(set_upstream_to: 'upstream/develop')
      end
    end

    context 'with missing set_upstream_to' do
      it 'raises ArgumentError' do
        expect { command.call }.to raise_error(ArgumentError)
      end

      it 'raises ArgumentError even when branch_name is provided' do
        expect { command.call('feature') }.to raise_error(ArgumentError)
      end
    end

    context 'with unsupported options' do
      it 'raises ArgumentError for unknown options' do
        expect { command.call(set_upstream_to: 'origin/main', unknown: true) }.to raise_error(ArgumentError, /unknown/)
      end
    end
  end
end
