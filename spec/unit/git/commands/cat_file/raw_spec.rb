# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/cat_file/raw'

RSpec.describe Git::Commands::CatFile::Raw do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#initialize' do
    it 'accepts an execution context' do
      expect { described_class.new(execution_context) }.not_to raise_error
    end
  end

  describe '#call' do
    context 'with -e mode' do
      it 'passes -e and the object name and returns the result' do
        expected_result = command_result('', exitstatus: 0)
        expect_command_capturing('cat-file', '-e', '--', 'HEAD').and_return(expected_result)

        result = command.call('HEAD', e: true)

        expect(result).to eq(expected_result)
      end
    end

    context 'with -t mode' do
      it 'passes -t and the object name' do
        expect_command_capturing('cat-file', '-t', '--', 'HEAD').and_return(command_result('commit'))

        command.call('HEAD', t: true)
      end
    end

    context 'with -s mode' do
      it 'passes -s and the object name' do
        expect_command_capturing('cat-file', '-s', '--', 'HEAD').and_return(command_result('42'))

        command.call('HEAD', s: true)
      end
    end

    context 'with -p mode' do
      it 'passes -p and the object name' do
        expect_command_capturing('cat-file', '-p', '--', 'HEAD').and_return(command_result('blob content'))

        command.call('HEAD', p: true)
      end
    end

    context 'with a type operand' do
      it 'passes type and object as positional arguments' do
        expect_command_capturing('cat-file', '--', 'blob', 'HEAD:README.md').and_return(command_result('# Hello'))

        command.call('blob', 'HEAD:README.md')
      end
    end

    context 'with :use_mailmap option' do
      it 'passes --use-mailmap when true' do
        expect_command_capturing('cat-file', '-t', '--use-mailmap', '--', 'HEAD').and_return(command_result('commit'))

        command.call('HEAD', t: true, use_mailmap: true)
      end

      it 'passes --no-use-mailmap when false' do
        expect_command_capturing('cat-file', '-t', '--no-use-mailmap', '--', 'HEAD')
          .and_return(command_result('commit'))

        command.call('HEAD', t: true, use_mailmap: false)
      end
    end

    context 'with :allow_unknown_type option' do
      it 'passes --allow-unknown-type' do
        expect_command_capturing('cat-file', '-t', '--allow-unknown-type', '--', 'HEAD')
          .and_return(command_result('commit'))

        command.call('HEAD', t: true, allow_unknown_type: true)
      end
    end

    context 'with out: execution option (streaming)' do
      it 'dispatches to command_streaming when out: is given' do
        out_io = instance_double(File)
        expect_command_streaming('cat-file', '-p', '--', 'HEAD', out: out_io).and_return(command_result(''))

        command.call('HEAD', p: true, out: out_io)
      end
    end

    context 'exit code handling' do
      it 'returns result for exit code 1 with -e (object not found)' do
        allow(execution_context).to receive(:command_capturing)
          .with('cat-file', '-e', '--', 'nonexistent', raise_on_failure: false)
          .and_return(command_result('', exitstatus: 1))

        result = command.call('nonexistent', e: true)

        expect(result.status.exitstatus).to eq(1)
      end

      it 'raises FailedError for exit code 128 with -e (catastrophic failure)' do
        allow(execution_context).to receive(:command_capturing)
          .with('cat-file', '-e', '--', 'HEAD', raise_on_failure: false)
          .and_return(command_result('', exitstatus: 128))

        expect { command.call('HEAD', e: true) }.to raise_error(Git::FailedError, /git/)
      end

      it 'raises FailedError for exit code 1 without -e' do
        allow(execution_context).to receive(:command_capturing)
          .with('cat-file', '-t', '--', 'HEAD', raise_on_failure: false)
          .and_return(command_result('', exitstatus: 1))

        expect { command.call('HEAD', t: true) }.to raise_error(Git::FailedError, /git/)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for an unsupported option' do
        expect { command.call('HEAD', bogus: true) }
          .to raise_error(ArgumentError, /bogus|Unsupported options/)
      end

      it 'raises ArgumentError when the required object argument is missing' do
        expect { command.call }.to raise_error(ArgumentError, /object is required/)
      end

      it 'raises ArgumentError when allow_unknown_type is used without -t or -s' do
        expect { command.call('HEAD', e: true, allow_unknown_type: true) }
          .to raise_error(ArgumentError, /:allow_unknown_type requires/)
      end
    end
  end
end
