# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::CommandLine do
  let(:env) { {} }
  let(:binary_path) { 'git' }
  let(:global_opts) { [] }
  let(:logger) { Logger.new(nil) }

  def mock_result(**overrides)
    default_options = {
      command: %w[git status],
      stdout: '',
      stderr: '',
      success?: true,
      signaled?: false,
      timed_out?: false
    }

    double('ProcessExecuter::ResultWithCapture', default_options.merge(overrides))
  end

  # Builds a mock ProcessExecuter::Result (non-capturing) for streaming tests
  def mock_streaming_result(**overrides)
    default_options = {
      command: %w[git status],
      success?: true,
      signaled?: false,
      timed_out?: false
    }

    double('ProcessExecuter::Result', default_options.merge(overrides))
  end

  subject(:command_line) do
    described_class.new(env, binary_path, global_opts, logger)
  end

  describe '#run (streaming path)' do
    context 'when command succeeds' do
      let(:stderr_io) { StringIO.new }

      before do
        mocked_result = mock_streaming_result(command: %w[git status], success?: true)
        allow(ProcessExecuter).to receive(:run).and_return(mocked_result)
      end

      it 'returns a CommandLineResult with empty stdout' do
        result = command_line.run('status', err: StringIO.new)

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).to eq('')
      end

      it 'captures stderr from the provided StringIO' do
        err_io = StringIO.new
        err_io << 'some warning'
        allow(ProcessExecuter).to receive(:run) do
          err_io << 'warning text'
          mock_streaming_result(command: %w[git status])
        end

        result = command_line.run('status', err: err_io)

        expect(result.stderr).to eq('some warningwarning text')
      end
    end

    context 'when raise_on_failure is true (default)' do
      before do
        mocked_result = mock_streaming_result(command: %w[git status], success?: false)
        allow(ProcessExecuter).to receive(:run).and_return(mocked_result)
      end

      it 'raises FailedError on non-zero exit status' do
        expect do
          command_line.run('status', err: StringIO.new)
        end.to raise_error(Git::FailedError)
      end
    end

    context 'when raise_on_failure is false' do
      before do
        mocked_result = mock_streaming_result(command: %w[git status], success?: false)
        allow(ProcessExecuter).to receive(:run).and_return(mocked_result)
      end

      it 'returns CommandLineResult on non-zero exit status without raising' do
        result = command_line.run('status', raise_on_failure: false, err: StringIO.new)

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.success?).to be false
      end
    end

    context 'when command times out' do
      before do
        mocked_result = mock_streaming_result(command: %w[git status], success?: false, timed_out?: true)
        allow(ProcessExecuter).to receive(:run).and_return(mocked_result)
      end

      it 'raises TimeoutError even with raise_on_failure: false' do
        expect do
          command_line.run('status', raise_on_failure: false, timeout: 1, err: StringIO.new)
        end.to raise_error(Git::TimeoutError)
      end
    end

    context 'when command is signaled' do
      before do
        mocked_result = mock_streaming_result(command: %w[git status], success?: false, signaled?: true)
        allow(ProcessExecuter).to receive(:run).and_return(mocked_result)
      end

      it 'raises SignaledError even with raise_on_failure: false' do
        expect do
          command_line.run('status', raise_on_failure: false, err: StringIO.new)
        end.to raise_error(Git::SignaledError)
      end
    end
  end

  describe '#run_with_capture with raise_on_failure option' do
    before do
      mocked_result = mock_result(command: %w[git status], stderr: 'fatal: not a git repository', success?: false)
      allow(ProcessExecuter).to receive(:run_with_capture).and_return(mocked_result)
    end

    context 'when raise_on_failure is true (default)' do
      it 'raises FailedError on non-zero exit status' do
        expect do
          command_line.run_with_capture('status')
        end.to raise_error(Git::FailedError)
      end
    end

    context 'when raise_on_failure is false' do
      it 'returns CommandLineResult on non-zero exit status without raising' do
        result = command_line.run_with_capture('status', raise_on_failure: false)

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.success?).to be false
      end

      context 'when command succeeds' do
        before do
          mocked_result = mock_result(success?: true)
          allow(ProcessExecuter).to receive(:run_with_capture).and_return(mocked_result)
        end

        it 'returns CommandLineResult on success' do
          result = command_line.run_with_capture('--version', raise_on_failure: false)

          expect(result).to be_a(Git::CommandLineResult)
          expect(result.status.success?).to be true
        end
      end
    end

    context 'timeout and signal errors are always raised' do
      context 'when command times out' do
        before do
          mocked_result = mock_result(success?: false, timed_out?: true)
          allow(ProcessExecuter).to receive(:run_with_capture).and_return(mocked_result)
        end

        it 'raises TimeoutError even with raise_on_failure: false' do
          expect do
            command_line.run_with_capture('status', raise_on_failure: false, timeout: 1)
          end.to raise_error(Git::TimeoutError)
        end
      end

      context 'when command is signaled' do
        before do
          mocked_result = mock_result(success?: false, signaled?: true)
          allow(ProcessExecuter).to receive(:run_with_capture).and_return(mocked_result)
        end

        it 'raises SignaledError even with raise_on_failure: false' do
          expect do
            command_line.run_with_capture('status', raise_on_failure: false)
          end.to raise_error(Git::SignaledError)
        end
      end
    end
  end
end
