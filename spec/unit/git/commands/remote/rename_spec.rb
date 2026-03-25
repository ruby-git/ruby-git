# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/remote/rename'

RSpec.describe Git::Commands::Remote::Rename do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with old and new names' do
      it 'passes both names' do
        expected_result = command_result
        expect_command_capturing('remote', 'rename', '--', 'origin', 'upstream').and_return(expected_result)

        result = command.call('origin', 'upstream')

        expect(result).to eq(expected_result)
      end
    end

    context 'with :progress option' do
      it 'includes --progress when true' do
        expect_command_capturing('remote', 'rename', '--progress', '--', 'origin',
                                 'upstream').and_return(command_result)

        command.call('origin', 'upstream', progress: true)
      end

      it 'includes --no-progress when false' do
        expect_command_capturing('remote', 'rename', '--no-progress', '--', 'origin',
                                 'upstream').and_return(command_result)

        command.call('origin', 'upstream', progress: false)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError when old name is missing' do
        expect { command.call }.to raise_error(ArgumentError, /old is required/)
      end

      it 'raises ArgumentError when new name is missing' do
        expect { command.call('origin') }.to raise_error(ArgumentError, /new is required/)
      end

      it 'raises ArgumentError for unsupported options' do
        expect { command.call('origin', 'upstream', verbose: true) }.to raise_error(ArgumentError, /unsupported/i)
      end
    end
  end
end
