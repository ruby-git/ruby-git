# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/config_option_syntax/remove_section'

RSpec.describe Git::Commands::ConfigOptionSyntax::RemoveSection do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with a name argument' do
      it 'runs git config --remove-section with the name' do
        expected_result = command_result
        expect_command_capturing('config', '--remove-section', '--', 'old-section').and_return(expected_result)

        result = command.call('old-section')
        expect(result).to eq(expected_result)
      end
    end

    context 'with the :global option' do
      it 'adds --global to the command line' do
        expect_command_capturing('config', '--remove-section', '--global', '--',
                                 'old-section').and_return(command_result)

        command.call('old-section', global: true)
      end
    end

    context 'with the :system option' do
      it 'adds --system to the command line' do
        expect_command_capturing('config', '--remove-section', '--system', '--',
                                 'old-section').and_return(command_result)

        command.call('old-section', system: true)
      end
    end

    context 'with the :local option' do
      it 'adds --local to the command line' do
        expect_command_capturing('config', '--remove-section', '--local', '--',
                                 'old-section').and_return(command_result)

        command.call('old-section', local: true)
      end
    end

    context 'with the :worktree option' do
      it 'adds --worktree to the command line' do
        expect_command_capturing('config', '--remove-section', '--worktree', '--',
                                 'old-section').and_return(command_result)

        command.call('old-section', worktree: true)
      end
    end

    context 'with the :file option' do
      it 'adds --file with the path' do
        expect_command_capturing('config', '--remove-section', '--file', '/path/to/config', '--',
                                 'old-section').and_return(command_result)

        command.call('old-section', file: '/path/to/config')
      end

      it 'supports the :f alias' do
        expect_command_capturing('config', '--remove-section', '--file', '/path/to/config', '--',
                                 'old-section').and_return(command_result)

        command.call('old-section', f: '/path/to/config')
      end
    end

    context 'with the :blob option' do
      it 'adds --blob with the value' do
        expect_command_capturing('config', '--remove-section', '--blob', 'HEAD:.gitmodules', '--',
                                 'old-section').and_return(command_result)

        command.call('old-section', blob: 'HEAD:.gitmodules')
      end
    end

    context 'input validation' do
      it 'raises ArgumentError when name is missing' do
        expect { command.call }.to raise_error(ArgumentError, /name/)
      end

      it 'raises ArgumentError for unsupported options' do
        expect { command.call('old-section', unknown: true) }.to raise_error(ArgumentError, /Unsupported options/)
      end
    end
  end
end
