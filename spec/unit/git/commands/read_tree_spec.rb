# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/read_tree'

RSpec.describe Git::Commands::ReadTree do
  # Duck-type collaborator: command specs depend on the #command_capturing
  # interface, not a single concrete ExecutionContext class.
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with a single tree-ish' do
      it 'runs git read-tree with the tree-ish as a positional argument' do
        expected_result = command_result
        expect_command_capturing('read-tree', '--', 'HEAD').and_return(expected_result)

        result = command.call('HEAD')

        expect(result).to eq(expected_result)
      end
    end

    context 'with multiple tree-ishes' do
      it 'passes all tree-ishes as positional arguments' do
        expect_command_capturing('read-tree', '--', 'abc123', 'def456', 'ghi789')
          .and_return(command_result)

        command.call('abc123', 'def456', 'ghi789')
      end
    end

    context 'with the :m option' do
      it 'adds -m to the command line' do
        expect_command_capturing('read-tree', '-m', '--', 'HEAD').and_return(command_result)

        command.call('HEAD', m: true)
      end
    end

    context 'with the :reset option' do
      it 'adds --reset to the command line' do
        expect_command_capturing('read-tree', '--reset', '--', 'HEAD').and_return(command_result)

        command.call('HEAD', reset: true)
      end
    end

    context 'with the :prefix option' do
      it 'adds --prefix=<value> as an inline value' do
        expect_command_capturing('read-tree', '--prefix=subdir/', '--', 'HEAD')
          .and_return(command_result)

        command.call('HEAD', prefix: 'subdir/')
      end
    end

    context 'with the :u option' do
      it 'adds -u to the command line' do
        expect_command_capturing('read-tree', '-u', '--', 'HEAD').and_return(command_result)

        command.call('HEAD', u: true)
      end
    end

    context 'with the :i option' do
      it 'adds -i to the command line' do
        expect_command_capturing('read-tree', '-i', '--', 'HEAD').and_return(command_result)

        command.call('HEAD', i: true)
      end
    end

    context 'with the :dry_run option' do
      it 'adds --dry-run to the command line' do
        expect_command_capturing('read-tree', '--dry-run', '--', 'HEAD').and_return(command_result)

        command.call('HEAD', dry_run: true)
      end
    end

    context 'with the :n alias' do
      it 'supports the :n alias for :dry_run' do
        expect_command_capturing('read-tree', '--dry-run', '--', 'HEAD').and_return(command_result)

        command.call('HEAD', n: true)
      end
    end

    context 'with the :v option' do
      it 'adds -v to the command line' do
        expect_command_capturing('read-tree', '-v', '--', 'HEAD').and_return(command_result)

        command.call('HEAD', v: true)
      end
    end

    context 'with the :trivial option' do
      it 'adds --trivial to the command line' do
        expect_command_capturing('read-tree', '--trivial', '--', 'HEAD').and_return(command_result)

        command.call('HEAD', trivial: true)
      end
    end

    context 'with the :aggressive option' do
      it 'adds --aggressive to the command line' do
        expect_command_capturing('read-tree', '--aggressive', '--', 'HEAD').and_return(command_result)

        command.call('HEAD', aggressive: true)
      end
    end

    context 'with the :index_output option' do
      it 'adds --index-output=<value> as an inline value' do
        expect_command_capturing('read-tree', '--index-output=/tmp/index', '--', 'HEAD')
          .and_return(command_result)

        command.call('HEAD', index_output: '/tmp/index')
      end
    end

    context 'with :recurse_submodules option' do
      context 'when true' do
        it 'adds --recurse-submodules flag' do
          expect_command_capturing('read-tree', '--recurse-submodules', '--', 'HEAD')
            .and_return(command_result)

          command.call('HEAD', recurse_submodules: true)
        end
      end

      context 'when :no_recurse_submodules is true' do
        it 'adds --no-recurse-submodules flag' do
          expect_command_capturing('read-tree', '--no-recurse-submodules', '--', 'HEAD')
            .and_return(command_result)

          command.call('HEAD', no_recurse_submodules: true)
        end
      end
    end

    context 'with the :no_sparse_checkout option' do
      it 'adds --no-sparse-checkout to the command line' do
        expect_command_capturing('read-tree', '--no-sparse-checkout', '--', 'HEAD')
          .and_return(command_result)

        command.call('HEAD', no_sparse_checkout: true)
      end
    end

    context 'with the :empty option' do
      it 'adds --empty to the command line' do
        expect_command_capturing('read-tree', '--empty').and_return(command_result)

        command.call(empty: true)
      end
    end

    context 'with the :quiet option' do
      it 'adds --quiet to the command line' do
        expect_command_capturing('read-tree', '--quiet', '--', 'HEAD').and_return(command_result)

        command.call('HEAD', quiet: true)
      end
    end

    context 'with the :q alias' do
      it 'supports the :q alias for :quiet' do
        expect_command_capturing('read-tree', '--quiet', '--', 'HEAD').and_return(command_result)

        command.call('HEAD', q: true)
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified flags in definition order' do
        expect_command_capturing(
          'read-tree',
          '-m',
          '--trivial', '--aggressive',
          '-u',
          '--quiet',
          '--',
          'base', 'ours', 'theirs'
        ).and_return(command_result)

        command.call('base', 'ours', 'theirs', m: true, trivial: true, aggressive: true, u: true, quiet: true)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call('HEAD', unknown: true) }
          .to raise_error(ArgumentError, /Unsupported options/)
      end
    end
  end
end
