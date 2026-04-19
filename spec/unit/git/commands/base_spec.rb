# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Commands::Base do
  let(:execution_context) { execution_context_double }

  describe '.arguments' do
    it 'stores a frozen args definition' do
      command_class = Class.new(described_class) do
        arguments do
          literal 'status'
        end
      end

      expect(command_class.args_definition).to be_a(Git::Commands::Arguments)
      expect(command_class.args_definition).to be_frozen
    end

    it 'raises ArgumentError when called twice on the same class' do
      command_class = Class.new(described_class) do
        arguments do
          literal 'status'
        end
      end

      expect do
        command_class.arguments do
          literal 'add'
        end
      end.to raise_error(ArgumentError, /arguments already defined/)
    end
  end

  describe '.requires_git_version' do
    let(:command_class) do
      Class.new(described_class) do
        arguments { literal 'status' }
      end
    end

    context 'with positional min' do
      it 'stores the normalized constraint' do
        command_class.requires_git_version '2.46.0'
        expect(command_class.git_version_constraint).to eq(
          Git::VersionConstraint.new(min: Git::Version.parse('2.46.0'), before: nil)
        )
      end
    end

    context 'with before: keyword only' do
      it 'stores the normalized constraint' do
        command_class.requires_git_version before: '2.50.0'
        expect(command_class.git_version_constraint).to eq(
          Git::VersionConstraint.new(min: nil, before: Git::Version.parse('2.50.0'))
        )
      end
    end

    context 'with min and before:' do
      it 'stores the normalized constraint' do
        command_class.requires_git_version '2.30.0', before: '2.50.0'
        expected = Git::VersionConstraint.new(
          min: Git::Version.parse('2.30.0'),
          before: Git::Version.parse('2.50.0')
        )
        expect(command_class.git_version_constraint).to eq(expected)
      end
    end

    it 'raises ArgumentError for a non-semver min string' do
      expect { command_class.requires_git_version '2.46' }
        .to raise_error(ArgumentError, /major\.minor\.patch/)
    end

    it 'raises ArgumentError for a non-semver before string' do
      expect { command_class.requires_git_version before: '2' }
        .to raise_error(ArgumentError, /major\.minor\.patch/)
    end

    it 'raises ArgumentError for Ruby Range objects' do
      expect { command_class.requires_git_version 1..2 }
        .to raise_error(ArgumentError, /major\.minor\.patch/)
    end

    it 'raises ArgumentError when called twice' do
      command_class.requires_git_version '2.30.0'
      expect { command_class.requires_git_version '2.35.0' }
        .to raise_error(ArgumentError, /requires_git_version already declared/)
    end

    it 'raises ArgumentError when no constraints are provided' do
      expect { command_class.requires_git_version }
        .to raise_error(ArgumentError, /requires min or before:/)
    end

    it 'raises ArgumentError for Hash argument' do
      expect { command_class.requires_git_version({ before: '2.30.0' }) }
        .to raise_error(ArgumentError, /major\.minor\.patch/)
    end

    it 'returns nil when not declared' do
      expect(command_class.git_version_constraint).to be_nil
    end
  end

  describe '.allow_exit_status' do
    let(:command_class) do
      Class.new(described_class) do
        arguments do
          literal 'status'
        end
      end
    end

    it 'raises ArgumentError for non-Range values' do
      expect { command_class.allow_exit_status(1) }
        .to raise_error(ArgumentError, /expects a Range/)
    end

    it 'raises ArgumentError when bounds are not Integers' do
      expect { command_class.allow_exit_status('0'..'1') }
        .to raise_error(ArgumentError, /bounds must be Integers/)
    end

    it 'raises ArgumentError for inverted ranges' do
      expect { command_class.allow_exit_status(2..1) }
        .to raise_error(ArgumentError, /range must not be empty/)
    end
  end

  describe '#call' do
    let(:command_class) do
      Class.new(described_class) do
        arguments do
          literal 'status'
          execution_option :timeout
        end
      end
    end
    let(:command) { command_class.new(execution_context) }

    it 'raises on non-zero exit status by default' do
      allow(execution_context).to receive(:command_capturing)
        .with('status', raise_on_failure: false)
        .and_return(command_result('', exitstatus: 1))

      expect { command.call }
        .to raise_error(Git::FailedError)
    end

    it 'accepts status 1 when allow_exit_status 0..1 is configured' do
      command_class.allow_exit_status(0..1)
      allow(execution_context).to receive(:command_capturing)
        .with('status', raise_on_failure: false)
        .and_return(command_result('', exitstatus: 1))

      result = command.call

      expect(result.status.exitstatus).to eq(1)
    end

    it 'accepts exit status values 1 through 7 when allow_exit_status 0..7 is configured' do
      command_class.allow_exit_status(0..7)

      (1..7).each do |exitstatus|
        allow(execution_context).to receive(:command_capturing)
          .with('status', raise_on_failure: false)
          .and_return(command_result('', exitstatus: exitstatus))

        result = command.call
        expect(result.status.exitstatus).to eq(exitstatus)
      end
    end

    it 'accepts exit status only when included in declared range' do
      command_class.allow_exit_status(0..1)
      allow(execution_context).to receive(:command_capturing)
        .with('status', raise_on_failure: false)
        .and_return(command_result('', exitstatus: 2))

      expect { command.call }
        .to raise_error(Git::FailedError)
    end

    it 'raises ArgumentError when arguments are not defined on the command class' do
      stub_const('Git::Commands::BaseSpecMissingArgsCommand', Class.new(described_class))
      no_args_command = Git::Commands::BaseSpecMissingArgsCommand.new(execution_context)

      expect { no_args_command.call }
        .to raise_error(ArgumentError, /arguments not defined/)
    end

    it 'propagates timeout errors from execution context' do
      timeout_error = Git::TimeoutError.new(command_result('', stderr: 'timed out'), 1)
      allow(execution_context).to receive(:command_capturing)
        .with('status', raise_on_failure: false)
        .and_raise(timeout_error)

      expect { command.call }
        .to raise_error(Git::TimeoutError)
    end

    it 'propagates signal errors from execution context' do
      signaled_error = Git::SignaledError.new(command_result('', stderr: 'killed'))
      allow(execution_context).to receive(:command_capturing)
        .with('status', raise_on_failure: false)
        .and_raise(signaled_error)

      expect { command.call }
        .to raise_error(Git::SignaledError)
    end

    it 'forwards execution options extracted from bound arguments' do
      allow(execution_context).to receive(:command_capturing)
        .with('status', timeout: 30, raise_on_failure: false)
        .and_return(command_result)

      command.call(timeout: 30)
    end

    it 'does not forward execution option keywords when none are provided' do
      allow(execution_context).to receive(:command_capturing)
        .with('status', raise_on_failure: false)
        .and_return(command_result)

      command.call
    end

    it 'does not forward extra keywords for commands without execution options' do
      no_exec_opts_class = Class.new(described_class) do
        arguments do
          literal 'status'
        end
      end
      no_exec_opts_command = no_exec_opts_class.new(execution_context)

      allow(execution_context).to receive(:command_capturing)
        .with('status', raise_on_failure: false)
        .and_return(command_result)

      no_exec_opts_command.call
    end

    context 'when execution_option :out is declared and provided' do
      let(:command_class) do
        Class.new(described_class) do
          arguments do
            literal 'cat-file'
            flag_option :p
            execution_option :out
            operand :object, required: true
          end
        end
      end
      let(:command) { command_class.new(execution_context) }

      it 'dispatches to command_streaming instead of command_capturing' do
        out_io = instance_double(File)
        allow(execution_context).to receive(:command_streaming)
          .with('cat-file', '-p', 'HEAD', out: out_io, raise_on_failure: false)
          .and_return(command_result(''))
        allow(execution_context).to receive(:command_capturing)

        command.call('HEAD', p: true, out: out_io)

        expect(execution_context).to have_received(:command_streaming)
        expect(execution_context).not_to have_received(:command_capturing)
      end

      it 'still dispatches to command_capturing when out: is not provided' do
        allow(execution_context).to receive(:command_capturing)
          .with('cat-file', '-p', 'HEAD', raise_on_failure: false)
          .and_return(command_result('content'))
        allow(execution_context).to receive(:command_streaming)

        command.call('HEAD', p: true)

        expect(execution_context).to have_received(:command_capturing)
        expect(execution_context).not_to have_received(:command_streaming)
      end
    end
  end

  describe '#with_stdin' do
    let(:command_class) do
      Class.new(described_class) do
        arguments { literal 'test' }

        def call(content)
          with_stdin(content, &:close)
        end
      end
    end
    let(:command) { command_class.new(execution_context) }

    context 'when the block closes the reader before the writer thread runs (simulates EPIPE)' do
      it 'handles EPIPE without raising' do
        expect { command.call('some content') }.not_to raise_error
      end
    end

    context 'when Thread.new raises before writer_thread can be assigned' do
      it 'handles nil writer_thread in ensure without raising' do
        # Thread.new raises before writer_thread can be assigned, so writer_thread
        # is nil in the ensure block — covers the else branch of writer_thread&.join
        allow(Thread).to receive(:new).and_raise(ThreadError, "can't alloc thread")
        expect { command.call('content') }.to raise_error(ThreadError)
      end
    end

    context 'when the writer is already closed when the thread ensure runs' do
      it 'skips writer.close when writer.closed? is true' do
        # Pre-close the writer so writer.closed? is true in start_stdin_writer's ensure,
        # covering the else branch of `writer.close unless writer.closed?`
        real_reader, real_writer = IO.pipe
        real_writer.close
        allow(IO).to receive(:pipe).and_return([real_reader, real_writer])
        expect { command.call('') }.not_to raise_error
      end
    end
  end

  describe '#call with version validation' do
    context 'with floor violation' do
      let(:command_class) do
        Class.new(described_class) do
          arguments { literal 'status' }
        end
      end
      let(:execution_context) { execution_context_double('2.27.0') }
      let(:command) { command_class.new(execution_context) }

      it 'raises VersionError when git version is below MINIMUM_GIT_VERSION' do
        expect { command.call }
          .to raise_error(Git::VersionError, /The git gem requires git >= 2.28.0/)
      end
    end

    context 'with class-level minimum version violation' do
      let(:command_class) do
        Class.new(described_class) do
          arguments { literal 'status' }
          requires_git_version '2.30.0'
        end
      end
      let(:execution_context) { execution_context_double('2.29.0') }
      let(:command) { command_class.new(execution_context) }

      it 'raises VersionError when git version is below class minimum' do
        expect { command.call }
          .to raise_error(Git::VersionError) do |error|
            expect(error.message).to match(/requires git >= 2.30.0/)
            expect(error.actual_version).to eq(Git::Version.parse('2.29.0'))
          end
      end
    end

    context 'with class-level upper bound violation' do
      let(:command_class) do
        Class.new(described_class) do
          arguments { literal 'status' }
          requires_git_version before: '2.50.0'
        end
      end
      let(:execution_context) { execution_context_double('2.51.0') }
      let(:command) { command_class.new(execution_context) }

      it 'raises VersionError when git version is at or above upper bound' do
        expect { command.call }
          .to raise_error(Git::VersionError) do |error|
            expect(error.message).to match(/requires git < 2.50.0/)
            expect(error.actual_version).to eq(Git::Version.parse('2.51.0'))
          end
      end
    end

    context 'floor check fail-fast behavior' do
      let(:command_class) do
        Class.new(described_class) do
          arguments { literal 'status' }
          requires_git_version '2.35.0'
        end
      end
      let(:execution_context) { execution_context_double('2.27.0') }
      let(:command) { command_class.new(execution_context) }

      it 'fails with floor message when both floor and class constraint would fail' do
        # Should fail with floor message, not class-level message
        expect { command.call }
          .to raise_error(Git::VersionError, /The git gem requires git >= 2.28.0/)
      end
    end

    context 'with sufficient version' do
      let(:command_class) do
        Class.new(described_class) do
          arguments { literal 'status' }
          requires_git_version '2.30.0'
        end
      end
      let(:execution_context) { execution_context_double('2.35.0') }
      let(:command) { command_class.new(execution_context) }

      it 'executes normally when version requirements are met' do
        allow(execution_context).to receive(:command_capturing)
          .with('status', raise_on_failure: false)
          .and_return(command_result)

        result = command.call
        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'without version constraint' do
      let(:command_class) do
        Class.new(described_class) do
          arguments { literal 'status' }
        end
      end
      let(:execution_context) { execution_context_double('2.35.0') }
      let(:command) { command_class.new(execution_context) }

      it 'executes normally when no version constraint is declared' do
        allow(execution_context).to receive(:command_capturing)
          .with('status', raise_on_failure: false)
          .and_return(command_result)

        result = command.call
        expect(result).to be_a(Git::CommandLineResult)
      end
    end
  end
end
