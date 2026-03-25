# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/remote/set_url_delete'

RSpec.describe Git::Commands::Remote::SetUrlDelete do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with name and url matcher' do
      it 'passes the delete form arguments' do
        expected_result = command_result
        expect_command_capturing('remote', 'set-url', '--delete', '--', 'origin', 'github').and_return(expected_result)

        result = command.call('origin', 'github')

        expect(result).to eq(expected_result)
      end
    end

    context 'with :push option' do
      it 'includes --push' do
        expect_command_capturing('remote', 'set-url', '--delete', '--push', '--', 'origin', 'github')
          .and_return(command_result)

        command.call('origin', 'github', push: true)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError when name is missing' do
        expect { command.call }.to raise_error(ArgumentError, /name is required/)
      end

      it 'raises ArgumentError when url is missing' do
        expect { command.call('origin') }.to raise_error(ArgumentError, /url is required/)
      end

      it 'raises ArgumentError for unsupported options' do
        expect { command.call('origin', 'github', add: true) }.to raise_error(ArgumentError, /unsupported/i)
      end
    end
  end
end
