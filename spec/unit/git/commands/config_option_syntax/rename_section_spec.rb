# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/config_option_syntax/rename_section'

RSpec.describe Git::Commands::ConfigOptionSyntax::RenameSection do
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with old_name and new_name arguments' do
      it 'runs git config --rename-section with old and new names' do
        expected_result = command_result
        expect_command_capturing('config', '--rename-section', '--', 'old-section',
                                 'new-section').and_return(expected_result)

        result = command.call('old-section', 'new-section')
        expect(result).to eq(expected_result)
      end
    end

    context 'with the :global option' do
      it 'adds --global to the command line' do
        expect_command_capturing('config', '--rename-section', '--global', '--', 'old-section',
                                 'new-section').and_return(command_result)

        command.call('old-section', 'new-section', global: true)
      end
    end

    context 'with the :system option' do
      it 'adds --system to the command line' do
        expect_command_capturing('config', '--rename-section', '--system', '--', 'old-section',
                                 'new-section').and_return(command_result)

        command.call('old-section', 'new-section', system: true)
      end
    end

    context 'with the :local option' do
      it 'adds --local to the command line' do
        expect_command_capturing('config', '--rename-section', '--local', '--', 'old-section',
                                 'new-section').and_return(command_result)

        command.call('old-section', 'new-section', local: true)
      end
    end

    context 'with the :worktree option' do
      it 'adds --worktree to the command line' do
        expect_command_capturing('config', '--rename-section', '--worktree', '--', 'old-section',
                                 'new-section').and_return(command_result)

        command.call('old-section', 'new-section', worktree: true)
      end
    end

    context 'with the :file option' do
      it 'adds --file with the path' do
        expect_command_capturing('config', '--rename-section', '--file', '/path/to/config', '--', 'old-section',
                                 'new-section').and_return(command_result)

        command.call('old-section', 'new-section', file: '/path/to/config')
      end

      it 'supports the :f alias' do
        expect_command_capturing('config', '--rename-section', '--file', '/path/to/config', '--', 'old-section',
                                 'new-section').and_return(command_result)

        command.call('old-section', 'new-section', f: '/path/to/config')
      end
    end

    context 'with the :blob option' do
      it 'adds --blob with the value' do
        expect_command_capturing('config', '--rename-section', '--blob', 'HEAD:.gitmodules', '--', 'old-section',
                                 'new-section').and_return(command_result)

        command.call('old-section', 'new-section', blob: 'HEAD:.gitmodules')
      end
    end

    context 'input validation' do
      it 'raises ArgumentError when old_name is missing' do
        expect { command.call }.to raise_error(ArgumentError, /old_name/)
      end

      it 'raises ArgumentError when new_name is missing' do
        expect { command.call('old-section') }.to raise_error(ArgumentError, /new_name/)
      end

      it 'raises ArgumentError for unsupported options' do
        expect do
          command.call('old-section', 'new-section', unknown: true)
        end.to raise_error(ArgumentError, /Unsupported options/)
      end
    end
  end
end
