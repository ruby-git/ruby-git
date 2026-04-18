# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/remote/set_head'

RSpec.describe Git::Commands::Remote::SetHead do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with a branch name' do
      it 'passes the remote name and branch' do
        expected_result = command_result
        expect_command_capturing('remote', 'set-head', 'origin', 'main').and_return(expected_result)

        result = command.call('origin', 'main')

        expect(result).to eq(expected_result)
      end
    end

    context 'with :auto option' do
      it 'includes --auto' do
        expect_command_capturing('remote', 'set-head', 'origin', '--auto').and_return(command_result)

        command.call('origin', auto: true)
      end

      it 'accepts :a alias' do
        expect_command_capturing('remote', 'set-head', 'origin', '--auto').and_return(command_result)

        command.call('origin', a: true)
      end
    end

    context 'with :delete option' do
      it 'includes --delete' do
        expect_command_capturing('remote', 'set-head', 'origin', '--delete').and_return(command_result)

        command.call('origin', delete: true)
      end

      it 'accepts :d alias' do
        expect_command_capturing('remote', 'set-head', 'origin', '--delete').and_return(command_result)

        command.call('origin', d: true)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError when name is missing' do
        expect { command.call }.to raise_error(ArgumentError, /name is required/)
      end

      it 'raises ArgumentError for unsupported options' do
        expect { command.call('origin', prune: true) }.to raise_error(ArgumentError, /unsupported/i)
      end
    end
  end
end
