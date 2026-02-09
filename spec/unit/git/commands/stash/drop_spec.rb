# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/drop'

RSpec.describe Git::Commands::Stash::Drop do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments (drop latest stash)' do
      it 'runs stash drop and returns CommandLineResult' do
        expect(execution_context).to receive(:command).with('stash', 'drop').and_return(command_result(''))

        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).to eq('')
      end
    end

    context 'with stash reference' do
      it 'drops specific stash by name' do
        expect(execution_context).to receive(:command)
          .with('stash', 'drop', 'stash@{0}').and_return(command_result(''))
        command.call('stash@{0}')
      end

      it 'drops specific stash by index' do
        expect(execution_context).to receive(:command)
          .with('stash', 'drop', 'stash@{2}').and_return(command_result(''))
        command.call('stash@{2}')
      end

      it 'drops stash using short form' do
        expect(execution_context).to receive(:command)
          .with('stash', 'drop', '1').and_return(command_result(''))
        command.call('1')
      end
    end
  end
end
