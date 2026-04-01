# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/commit_tree'

RSpec.describe Git::Commands::CommitTree do
  # Duck-type collaborator: command specs depend on the #command_capturing
  # interface, not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with only the tree operand' do
      it 'runs git commit-tree with the tree as a positional argument' do
        expected_result = command_result
        expect_command_capturing('commit-tree', '--', 'abc123').and_return(expected_result)

        result = command.call('abc123')

        expect(result).to eq(expected_result)
      end
    end

    context 'with the :m option' do
      it 'adds -m <message> to the command line' do
        expect_command_capturing('commit-tree', '-m', 'Initial commit', '--', 'abc123')
          .and_return(command_result)

        command.call('abc123', m: 'Initial commit')
      end
    end

    context 'with an empty message' do
      it 'adds -m with an empty string to the command line' do
        expect_command_capturing('commit-tree', '-m', '', '--', 'abc123')
          .and_return(command_result)

        command.call('abc123', m: '')
      end
    end

    context 'with multiple messages' do
      it 'adds multiple -m flags when given an array' do
        expect_command_capturing('commit-tree', '-m', 'paragraph 1', '-m', 'paragraph 2', '--', 'abc123')
          .and_return(command_result)

        command.call('abc123', m: ['paragraph 1', 'paragraph 2'])
      end
    end

    context 'with the :p option' do
      it 'adds -p <parent> to the command line' do
        expect_command_capturing('commit-tree', '-p', 'parent1', '--', 'abc123')
          .and_return(command_result)

        command.call('abc123', p: 'parent1')
      end
    end

    context 'with multiple parents' do
      it 'adds multiple -p flags when given an array' do
        expect_command_capturing('commit-tree', '-p', 'parent1', '-p', 'parent2', '--', 'abc123')
          .and_return(command_result)

        command.call('abc123', p: %w[parent1 parent2])
      end
    end

    context 'with the :F option' do
      it 'adds -F <file> to the command line' do
        expect_command_capturing('commit-tree', '-F', '/path/to/msg.txt', '--', 'abc123')
          .and_return(command_result)

        command.call('abc123', F: '/path/to/msg.txt')
      end
    end

    context 'with multiple files' do
      it 'adds multiple -F flags when given an array' do
        expect_command_capturing('commit-tree', '-F', 'msg1.txt', '-F', 'msg2.txt', '--', 'abc123')
          .and_return(command_result)

        command.call('abc123', F: %w[msg1.txt msg2.txt])
      end
    end

    context 'with the :gpg_sign option' do
      it 'adds --gpg-sign when true' do
        expect_command_capturing('commit-tree', '--gpg-sign', '--', 'abc123')
          .and_return(command_result)

        command.call('abc123', gpg_sign: true)
      end

      it 'adds --gpg-sign=<key-id> when given a string' do
        expect_command_capturing('commit-tree', '--gpg-sign=ABCD1234', '--', 'abc123')
          .and_return(command_result)

        command.call('abc123', gpg_sign: 'ABCD1234')
      end

      it 'adds --no-gpg-sign when false' do
        expect_command_capturing('commit-tree', '--no-gpg-sign', '--', 'abc123')
          .and_return(command_result)

        command.call('abc123', gpg_sign: false)
      end
    end

    context 'with the :S alias' do
      it 'supports the :S alias for :gpg_sign' do
        expect_command_capturing('commit-tree', '--gpg-sign', '--', 'abc123')
          .and_return(command_result)

        command.call('abc123', S: true)
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified options in definition order' do
        expect_command_capturing(
          'commit-tree',
          '-p', 'parent1', '-p', 'parent2',
          '--gpg-sign=MYKEY',
          '-m', 'merge commit',
          '--', 'tree-sha'
        ).and_return(command_result)

        command.call('tree-sha', p: %w[parent1 parent2], m: 'merge commit', gpg_sign: 'MYKEY')
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call('abc123', unknown: true) }
          .to raise_error(ArgumentError, /Unsupported options/)
      end

      it 'raises ArgumentError when tree operand is missing' do
        expect { command.call }
          .to raise_error(ArgumentError, /tree is required/)
      end
    end
  end
end
