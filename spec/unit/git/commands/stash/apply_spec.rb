# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/apply'

RSpec.describe Git::Commands::Stash::Apply do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments (apply latest stash)' do
      it 'runs stash apply' do
        expect_command('stash', 'apply').and_return(command_result(''))

        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).to eq('')
      end
    end

    context 'with stash reference' do
      it 'applies specific stash by name' do
        expect_command('stash', 'apply', 'stash@{0}').and_return(command_result(''))
        command.call('stash@{0}')
      end

      it 'applies specific stash by index' do
        expect_command('stash', 'apply', 'stash@{2}').and_return(command_result(''))
        command.call('stash@{2}')
      end

      it 'applies stash using short form' do
        expect_command('stash', 'apply', '1').and_return(command_result(''))
        command.call('1')
      end
    end

    context 'with :index option' do
      it 'adds --index flag to restore index state' do
        expect_command('stash', 'apply', '--index').and_return(command_result(''))
        command.call(index: true)
      end

      it 'does not add flag when false' do
        expect_command('stash', 'apply').and_return(command_result(''))
        command.call(index: false)
      end
    end

    context 'with stash reference and options' do
      it 'combines stash reference with index option' do
        expect_command('stash', 'apply', '--index', 'stash@{1}').and_return(command_result(''))
        command.call('stash@{1}', index: true)
      end
    end
  end
end
