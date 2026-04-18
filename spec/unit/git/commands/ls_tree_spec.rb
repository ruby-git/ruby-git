# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/ls_tree'

RSpec.describe Git::Commands::LsTree do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with only the required tree_ish argument' do
      it 'runs git ls-tree with only the tree-ish' do
        expected_result = command_result
        expect_command_capturing('ls-tree', '--', 'HEAD').and_return(expected_result)

        result = command.call('HEAD')

        expect(result).to eq(expected_result)
      end
    end

    context 'with the :d option' do
      it 'adds -d to the command line' do
        expect_command_capturing('ls-tree', '-d', '--', 'HEAD').and_return(command_result)

        command.call('HEAD', d: true)
      end
    end

    context 'with the :r option' do
      it 'adds -r to the command line' do
        expect_command_capturing('ls-tree', '-r', '--', 'HEAD').and_return(command_result)

        command.call('HEAD', r: true)
      end
    end

    context 'with the :t option' do
      it 'adds -t to the command line' do
        expect_command_capturing('ls-tree', '-t', '--', 'HEAD').and_return(command_result)

        command.call('HEAD', t: true)
      end
    end

    context 'with the :long option' do
      it 'adds --long to the command line' do
        expect_command_capturing('ls-tree', '--long', '--', 'HEAD').and_return(command_result)

        command.call('HEAD', long: true)
      end

      it 'supports the :l alias' do
        expect_command_capturing('ls-tree', '--long', '--', 'HEAD').and_return(command_result)

        command.call('HEAD', l: true)
      end
    end

    context 'with the :z option' do
      it 'adds -z to the command line' do
        expect_command_capturing('ls-tree', '-z', '--', 'HEAD').and_return(command_result)

        command.call('HEAD', z: true)
      end
    end

    context 'with the :name_only option' do
      it 'adds --name-only to the command line' do
        expect_command_capturing('ls-tree', '--name-only', '--', 'HEAD').and_return(command_result)

        command.call('HEAD', name_only: true)
      end
    end

    context 'with the :name_status option' do
      it 'adds --name-only to the command line (name_status is an alias for name_only)' do
        expect_command_capturing('ls-tree', '--name-only', '--', 'HEAD').and_return(command_result)

        command.call('HEAD', name_status: true)
      end
    end

    context 'with the :object_only option' do
      it 'adds --object-only to the command line' do
        expect_command_capturing('ls-tree', '--object-only', '--', 'HEAD').and_return(command_result)

        command.call('HEAD', object_only: true)
      end
    end

    context 'with the :full_name option' do
      it 'adds --full-name to the command line' do
        expect_command_capturing('ls-tree', '--full-name', '--', 'HEAD').and_return(command_result)

        command.call('HEAD', full_name: true)
      end
    end

    context 'with the :full_tree option' do
      it 'adds --full-tree to the command line' do
        expect_command_capturing('ls-tree', '--full-tree', '--', 'HEAD').and_return(command_result)

        command.call('HEAD', full_tree: true)
      end
    end

    context 'with the :abbrev option' do
      it 'adds --abbrev when true' do
        expect_command_capturing('ls-tree', '--abbrev', '--', 'HEAD').and_return(command_result)

        command.call('HEAD', abbrev: true)
      end

      it 'adds --abbrev=<n> when a string is given' do
        expect_command_capturing('ls-tree', '--abbrev=8', '--', 'HEAD').and_return(command_result)

        command.call('HEAD', abbrev: '8')
      end
    end

    context 'with the :format option' do
      it 'adds --format=<format> to the command line' do
        expect_command_capturing('ls-tree', '--format=%(objectname)', '--', 'HEAD').and_return(command_result)

        command.call('HEAD', format: '%(objectname)')
      end
    end

    context 'with a single path operand' do
      it 'appends the path after the tree-ish' do
        expect_command_capturing('ls-tree', '--', 'HEAD', 'lib/').and_return(command_result)

        command.call('HEAD', 'lib/')
      end
    end

    context 'with multiple path operands' do
      it 'appends all paths after the tree-ish' do
        expect_command_capturing('ls-tree', '--', 'HEAD', 'lib/', 'spec/').and_return(command_result)

        command.call('HEAD', 'lib/', 'spec/')
      end
    end

    context 'with options and path operands combined' do
      it 'places flags before --, tree-ish and paths after --' do
        expect_command_capturing('ls-tree', '-r', '--', 'HEAD', 'lib/').and_return(command_result)

        command.call('HEAD', 'lib/', r: true)
      end
    end

    context 'with :r and :t options combined' do
      it 'adds both -r and -t to the command line' do
        expect_command_capturing('ls-tree', '-r', '-t', '--', 'HEAD').and_return(command_result)

        command.call('HEAD', r: true, t: true)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError when tree_ish is missing' do
        expect { command.call }.to raise_error(ArgumentError, /tree_ish/)
      end

      it 'raises ArgumentError for unsupported options' do
        expect { command.call('HEAD', unknown_flag: true) }.to(
          raise_error(ArgumentError, /Unsupported options/)
        )
      end
    end
  end
end
