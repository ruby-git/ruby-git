# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/remote/set_url'

RSpec.describe Git::Commands::Remote::SetUrl do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with name and new url' do
      it 'passes the remote name and replacement url' do
        expected_result = command_result
        expect_command_capturing('remote', 'set-url', '--', 'origin', 'https://example.com/repo.git').and_return(expected_result)

        result = command.call('origin', 'https://example.com/repo.git')

        expect(result).to eq(expected_result)
      end
    end

    context 'with old url matcher' do
      it 'passes the matcher after the new url' do
        expect_command_capturing(
          'remote', 'set-url', '--', 'origin', 'https://example.com/repo.git', 'github'
        ).and_return(command_result)

        command.call('origin', 'https://example.com/repo.git', 'github')
      end
    end

    context 'with :push option' do
      it 'includes --push' do
        expect_command_capturing('remote', 'set-url', '--push', '--', 'origin', 'https://example.com/repo.git')
          .and_return(command_result)

        command.call('origin', 'https://example.com/repo.git', push: true)
      end
    end

    context 'with :push option and old url matcher' do
      it 'includes --push before the separator and oldurl after newurl' do
        expect_command_capturing(
          'remote', 'set-url', '--push', '--', 'origin', 'https://example.com/repo.git', 'github'
        ).and_return(command_result)

        command.call('origin', 'https://example.com/repo.git', 'github', push: true)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call('origin', 'https://example.com/repo.git', all: true) }
          .to raise_error(ArgumentError, /unsupported/i)
      end
    end
  end
end
