# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/show_ref/exists'

RSpec.describe Git::Commands::ShowRef::Exists do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with a ref name' do
      it 'runs git show-ref --exists <ref>' do
        expected_result = command_result
        expect_command_capturing('show-ref', '--exists', 'refs/heads/main').and_return(expected_result)

        result = command.call('refs/heads/main')

        expect(result).to eq(expected_result)
      end
    end

    context 'with the :timeout execution option' do
      it 'passes timeout to the execution context' do
        expect_command_capturing('show-ref', '--exists', 'refs/heads/main', timeout: 5)
          .and_return(command_result)

        command.call('refs/heads/main', timeout: 5)
      end
    end

    context 'exit code handling' do
      it 'returns normally on exit code 0 (ref found)' do
        expect_command_capturing('show-ref', '--exists', 'refs/heads/main')
          .and_return(command_result(exitstatus: 0))

        result = command.call('refs/heads/main')

        expect(result.status.exitstatus).to eq(0)
      end

      it 'returns normally on exit code 1 (lookup error)' do
        expect_command_capturing('show-ref', '--exists', 'refs/heads/main')
          .and_return(command_result(exitstatus: 1))

        result = command.call('refs/heads/main')

        expect(result.status.exitstatus).to eq(1)
      end

      it 'returns normally on exit code 2 (ref not found)' do
        expect_command_capturing('show-ref', '--exists', 'refs/heads/nonexistent')
          .and_return(command_result(exitstatus: 2))

        result = command.call('refs/heads/nonexistent')

        expect(result.status.exitstatus).to eq(2)
      end

      it 'raises Git::FailedError on exit code 3' do
        expect_command_capturing('show-ref', '--exists', 'refs/heads/main')
          .and_return(command_result(exitstatus: 3))

        expect { command.call('refs/heads/main') }.to raise_error(Git::FailedError, /git/)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError when no ref is provided' do
        expect { command.call }.to raise_error(ArgumentError, /ref/)
      end

      it 'raises ArgumentError for unsupported options' do
        expect { command.call('refs/heads/main', bogus: true) }
          .to raise_error(ArgumentError, /Unsupported options/)
      end
    end
  end
end
