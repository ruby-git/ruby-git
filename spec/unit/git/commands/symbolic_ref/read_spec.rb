# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/symbolic_ref/read'

RSpec.describe Git::Commands::SymbolicRef::Read do
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with a name operand' do
      it 'runs git symbolic-ref with the name' do
        expected_result = command_result('refs/heads/main')
        expect_command_capturing('symbolic-ref', '--', 'HEAD')
          .and_return(expected_result)

        result = command.call('HEAD')

        expect(result).to eq(expected_result)
      end
    end

    context 'with the :quiet option' do
      it 'adds --quiet to the command line' do
        expect_command_capturing('symbolic-ref', '--quiet', '--', 'HEAD')
          .and_return(command_result('refs/heads/main'))

        command.call('HEAD', quiet: true)
      end
    end

    context 'with the :q alias' do
      it 'adds --quiet to the command line' do
        expect_command_capturing('symbolic-ref', '--quiet', '--', 'HEAD')
          .and_return(command_result('refs/heads/main'))

        command.call('HEAD', q: true)
      end
    end

    context 'with the :short option' do
      it 'adds --short to the command line' do
        expect_command_capturing('symbolic-ref', '--short', '--', 'HEAD')
          .and_return(command_result('main'))

        command.call('HEAD', short: true)
      end
    end

    context 'with the :recurse option' do
      it 'adds --recurse to the command line when true' do
        expect_command_capturing('symbolic-ref', '--recurse', '--', 'HEAD')
          .and_return(command_result('refs/heads/main'))

        command.call('HEAD', recurse: true)
      end

      it 'adds --no-recurse to the command line when false' do
        expect_command_capturing('symbolic-ref', '--no-recurse', '--', 'HEAD')
          .and_return(command_result('refs/heads/main'))

        command.call('HEAD', recurse: false)
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified options in definition order' do
        expect_command_capturing('symbolic-ref', '--quiet', '--short', '--', 'HEAD')
          .and_return(command_result('main'))

        command.call('HEAD', quiet: true, short: true)
      end
    end

    context 'exit code handling' do
      it 'returns normally on exit code 0' do
        expect_command_capturing('symbolic-ref', '--', 'HEAD')
          .and_return(command_result(exitstatus: 0))

        result = command.call('HEAD')

        expect(result.status.exitstatus).to eq(0)
      end

      it 'returns normally on exit code 1 (not a symbolic ref)' do
        expect_command_capturing('symbolic-ref', '--', 'HEAD')
          .and_return(command_result(exitstatus: 1))

        result = command.call('HEAD')

        expect(result.status.exitstatus).to eq(1)
      end

      it 'raises Git::FailedError on exit code 2' do
        expect_command_capturing('symbolic-ref', '--', 'HEAD')
          .and_return(command_result(exitstatus: 2))

        expect { command.call('HEAD') }.to raise_error(Git::FailedError, /git/)
      end

      it 'raises Git::FailedError on exit code 128' do
        expect_command_capturing('symbolic-ref', '--', 'HEAD')
          .and_return(command_result(exitstatus: 128))

        expect { command.call('HEAD') }.to raise_error(Git::FailedError, /git/)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call('HEAD', unknown: true) }
          .to raise_error(ArgumentError, /Unsupported options/)
      end

      it 'raises ArgumentError when the name operand is missing' do
        expect { command.call }
          .to raise_error(ArgumentError, /name is required/)
      end
    end
  end
end
