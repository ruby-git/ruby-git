# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/checkout_index'

RSpec.describe Git::Commands::CheckoutIndex do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments' do
      it 'runs git checkout-index without any flags' do
        expected_result = command_result
        expect_command('checkout-index').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with the :all option' do
      it 'includes --all when true' do
        expect_command('checkout-index', '--all').and_return(command_result)

        command.call(all: true)
      end

      it 'accepts :a as an alias' do
        expect_command('checkout-index', '--all').and_return(command_result)

        command.call(a: true)
      end

      it 'does not include --all when false' do
        expect_command('checkout-index').and_return(command_result)

        command.call(all: false)
      end
    end

    context 'with the :force option' do
      it 'includes --force when true' do
        expect_command('checkout-index', '--force').and_return(command_result)

        command.call(force: true)
      end

      it 'accepts :f as an alias' do
        expect_command('checkout-index', '--force').and_return(command_result)

        command.call(f: true)
      end

      it 'does not include --force when false' do
        expect_command('checkout-index').and_return(command_result)

        command.call(force: false)
      end
    end

    context 'with the :index option' do
      it 'includes --index when true' do
        expect_command('checkout-index', '--index').and_return(command_result)

        command.call(index: true)
      end

      it 'accepts :u as an alias' do
        expect_command('checkout-index', '--index').and_return(command_result)

        command.call(u: true)
      end
    end

    context 'with the :no_create option' do
      it 'includes --no-create when true' do
        expect_command('checkout-index', '--no-create').and_return(command_result)

        command.call(no_create: true)
      end

      it 'accepts :n as an alias' do
        expect_command('checkout-index', '--no-create').and_return(command_result)

        command.call(n: true)
      end
    end

    context 'with the :prefix option' do
      it 'includes --prefix=<value>' do
        expect_command('checkout-index', '--prefix=output/').and_return(command_result)

        command.call(prefix: 'output/')
      end
    end

    context 'with the :stage option' do
      it 'includes --stage=<value>' do
        expect_command('checkout-index', '--stage=2').and_return(command_result)

        command.call(stage: '2')
      end

      it 'accepts "all" as the stage value' do
        expect_command('checkout-index', '--stage=all').and_return(command_result)

        command.call(stage: 'all')
      end
    end

    context 'with the :temp option' do
      it 'includes --temp when true' do
        expect_command('checkout-index', '--temp').and_return(command_result)

        command.call(temp: true)
      end
    end

    context 'with the :ignore_skip_worktree_bits option' do
      it 'includes --ignore-skip-worktree-bits when true' do
        expect_command('checkout-index', '--ignore-skip-worktree-bits').and_return(command_result)

        command.call(ignore_skip_worktree_bits: true)
      end
    end

    context 'with path_limiter positional arguments' do
      it 'appends -- and a single path' do
        expect_command('checkout-index', '--', 'file.txt').and_return(command_result)

        command.call('file.txt')
      end

      it 'appends -- and multiple paths when given as separate arguments' do
        expect_command('checkout-index', '--', 'file1.txt', 'file2.txt').and_return(command_result)

        command.call('file1.txt', 'file2.txt')
      end

      it 'omits -- when no paths are given' do
        expect_command('checkout-index').and_return(command_result)

        command.call
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified flags' do
        expect_command('checkout-index', '--all', '--force', '--prefix=output/').and_return(command_result)

        command.call(prefix: 'output/', force: true, all: true)
      end
    end

    context 'with :force and file operand combined' do
      it 'includes --force and appends -- path' do
        expect_command('checkout-index', '--force', '--', 'file.txt').and_return(command_result)

        command.call('file.txt', force: true)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call(invalid_option: true) }.to(
          raise_error(ArgumentError, /Unsupported options: :invalid_option/)
        )
      end
    end
  end
end
