# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/merge/resolve'

RSpec.describe Git::Commands::Merge::Resolve do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with :abort option' do
      it 'calls git merge --abort' do
        expect(execution_context).to receive(:command).with('merge', '--abort')
        command.call(abort: true)
      end

      it 'does not add flag when false' do
        expect(execution_context).to receive(:command).with('merge')
        command.call(abort: false)
      end
    end

    context 'with :continue option' do
      it 'calls git merge --continue' do
        expect(execution_context).to receive(:command).with('merge', '--continue')
        command.call(continue: true)
      end

      it 'does not add flag when false' do
        expect(execution_context).to receive(:command).with('merge')
        command.call(continue: false)
      end
    end

    context 'with :quit option' do
      it 'calls git merge --quit' do
        expect(execution_context).to receive(:command).with('merge', '--quit')
        command.call(quit: true)
      end

      it 'does not add flag when false' do
        expect(execution_context).to receive(:command).with('merge')
        command.call(quit: false)
      end
    end

    context 'with conflicting options' do
      it 'raises error when abort and continue are both true' do
        expect { command.call(abort: true, continue: true) }.to raise_error(ArgumentError, /cannot specify/)
      end

      it 'raises error when abort and quit are both true' do
        expect { command.call(abort: true, quit: true) }.to raise_error(ArgumentError, /cannot specify/)
      end

      it 'raises error when continue and quit are both true' do
        expect { command.call(continue: true, quit: true) }.to raise_error(ArgumentError, /cannot specify/)
      end

      it 'raises error when all three are true' do
        expect { command.call(abort: true, continue: true, quit: true) }.to raise_error(ArgumentError, /cannot specify/)
      end
    end

    context 'with no options' do
      it 'calls git merge with no flags' do
        expect(execution_context).to receive(:command).with('merge')
        command.call
      end
    end
  end
end
