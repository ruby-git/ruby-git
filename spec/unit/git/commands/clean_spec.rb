# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Commands::Clean do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments' do
      it 'runs git clean without any flags' do
        expected_result = command_result
        expect_command('clean').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with the :force argument' do
      it 'adds --force to the command line' do
        expect_command('clean', '--force').and_return(command_result)

        command.call(force: true)
      end
    end

    context 'with the :force_force argument' do
      it 'adds -ff to the command line' do
        expect_command('clean', '-ff').and_return(command_result)
        command.call(force_force: true)
      end
    end

    context 'with both :force and :force_force arguments' do
      it 'allows force: true with force_force: false' do
        expect_command('clean', '--force').and_return(command_result)
        command.call(force: true, force_force: false)
      end

      it 'allows force_force: true with force: false' do
        expect_command('clean', '-ff').and_return(command_result)
        command.call(force_force: true, force: false)
      end
    end

    context 'with the :d argument' do
      it 'adds -d to the command line' do
        expect_command('clean', '-d').and_return(command_result)

        command.call(d: true)
      end
    end

    context 'with the :x argument' do
      it 'adds -x to the command line' do
        expect_command('clean', '-x').and_return(command_result)

        command.call(x: true)
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified flags' do
        expect_command('clean', '--force', '-d', '-x').and_return(command_result)
        command.call(force: true, d: true, x: true)
      end
    end

    context 'input validation' do
      it 'raises an ArgumentError when both :force and :force_force are true' do
        expect { command.call(force: true, force_force: true) }.to(
          raise_error(ArgumentError, /cannot specify :force and :force_force/)
        )
      end

      it 'raises an ArgumentError for unexpected options' do
        expect { command.call(unexpected: true) }.to(
          raise_error(ArgumentError, /Unsupported options: :unexpected/)
        )
      end

      it 'raises an ArgumentError for unexpected positional arguments' do
        expect { command.call('unexpected') }.to(
          raise_error(ArgumentError, /Unexpected positional arguments: unexpected/)
        )
      end
    end
  end
end
