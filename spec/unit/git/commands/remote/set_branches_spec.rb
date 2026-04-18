# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/remote/set_branches'

RSpec.describe Git::Commands::Remote::SetBranches do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with a single branch' do
      it 'passes the remote name and branch' do
        expected_result = command_result
        expect_command_capturing('remote', 'set-branches', '--', 'origin', 'main').and_return(expected_result)

        result = command.call('origin', 'main')

        expect(result).to eq(expected_result)
      end
    end

    context 'with multiple branches' do
      it 'passes all branch operands' do
        expect_command_capturing('remote', 'set-branches', '--', 'origin', 'main',
                                 'release/*').and_return(command_result)

        command.call('origin', 'main', 'release/*')
      end
    end

    context 'with :add option' do
      it 'includes --add' do
        expect_command_capturing('remote', 'set-branches', '--add', '--', 'origin', 'main').and_return(command_result)

        command.call('origin', 'main', add: true)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call('origin', 'main', fetch: true) }.to raise_error(ArgumentError, /unsupported/i)
      end
    end
  end
end
