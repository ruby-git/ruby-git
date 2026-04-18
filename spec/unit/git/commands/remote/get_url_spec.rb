# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/remote/get_url'

RSpec.describe Git::Commands::Remote::GetUrl do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with a remote name' do
      it 'passes the remote name' do
        expected_result = command_result("https://example.com/repo.git\n")
        expect_command_capturing('remote', 'get-url', '--', 'origin').and_return(expected_result)

        result = command.call('origin')

        expect(result).to eq(expected_result)
      end
    end

    context 'with :push option' do
      it 'includes --push' do
        expect_command_capturing('remote', 'get-url', '--push', '--', 'origin').and_return(command_result)

        command.call('origin', push: true)
      end
    end

    context 'with :all option' do
      it 'includes --all' do
        expect_command_capturing('remote', 'get-url', '--all', '--', 'origin').and_return(command_result)

        command.call('origin', all: true)
      end
    end

    context 'with multiple options' do
      it 'combines flags before the name operand' do
        expect_command_capturing('remote', 'get-url', '--push', '--all', '--', 'origin').and_return(command_result)

        command.call('origin', push: true, all: true)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError when name is missing' do
        expect { command.call }.to raise_error(ArgumentError, /name is required/)
      end

      it 'raises ArgumentError for unsupported options' do
        expect { command.call('origin', verbose: true) }.to raise_error(ArgumentError, /unsupported/i)
      end
    end
  end
end
