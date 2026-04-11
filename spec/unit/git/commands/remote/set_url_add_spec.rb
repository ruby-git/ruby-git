# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/remote/set_url_add'

RSpec.describe Git::Commands::Remote::SetUrlAdd do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with name and new url' do
      it 'passes the add form arguments' do
        expected_result = command_result
        expect_command_capturing('remote', 'set-url', '--add', '--', 'origin', 'https://example.com/repo.git')
          .and_return(expected_result)

        result = command.call('origin', 'https://example.com/repo.git')

        expect(result).to eq(expected_result)
      end
    end

    context 'with :push option' do
      it 'includes --push' do
        expect_command_capturing('remote', 'set-url', '--add', '--push', '--', 'origin', 'https://example.com/repo.git')
          .and_return(command_result)

        command.call('origin', 'https://example.com/repo.git', push: true)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call('origin', 'https://example.com/repo.git', delete: true) }
          .to raise_error(ArgumentError, /unsupported/i)
      end
    end
  end
end
