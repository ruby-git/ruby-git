# frozen_string_literal: true

require 'spec_helper'
require 'git/command_line/streaming'

RSpec.describe Git::CommandLine::Streaming do
  let(:env) { {} }
  let(:binary_path) { 'git' }
  let(:global_opts) { [] }
  let(:logger) { Logger.new(nil) }
  let(:described_instance) { described_class.new(env, binary_path, global_opts, logger) }

  describe '#initialize' do
    subject(:instance) { described_instance }

    it 'stores all constructor arguments' do
      expect(instance).to have_attributes(
        env: env,
        binary_path: binary_path,
        global_opts: global_opts,
        logger: logger
      )
    end
  end

  # Builds a mock ProcessExecuter::Result (non-capturing) for streaming tests.
  # Plain double: ProcessExecuter result classes delegate to Process::Status via
  # SimpleDelegator/method_missing, so instance_double cannot verify the delegated
  # interface (signaled?, exitstatus, etc.).
  def mock_result(**overrides)
    defaults = {
      command: %w[git cat-file],
      success?: true,
      signaled?: false,
      timed_out?: false
    }
    double('ProcessExecuter::Result', defaults.merge(overrides))
  end

  describe '#run' do
    subject(:result) { described_instance.run(*run_args, **run_opts) }

    let(:run_args) { ['cat-file', 'blob', 'HEAD:README.md'] }
    let(:run_opts) { {} }

    context 'with no options' do
      before do
        allow(ProcessExecuter).to receive(:run).and_return(mock_result)
      end

      it 'returns a result with empty stdout and stderr' do
        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).to eq('')
        expect(result.stderr).to eq('')
      end
    end

    context 'when the subprocess writes to stderr' do
      before do
        allow(ProcessExecuter).to receive(:run) do |*_args, err:, **_opts|
          err.write('warning from git')
          mock_result
        end
      end

      it 'captures stderr in result.stderr' do
        expect(result.stderr).to eq('warning from git')
      end
    end

    context 'with err: option' do
      let(:err_io) { StringIO.new }
      let(:run_opts) { { err: err_io } }

      before do
        allow(ProcessExecuter).to receive(:run) do |*_args, err:, **_opts|
          err.write('warning from git')
          mock_result
        end
      end

      it 'tees stderr to the caller-provided err: IO' do
        expect { result }.to change(err_io, :string).from('').to('warning from git')
      end

      it 'also captures stderr in result.stderr' do
        expect(result.stderr).to eq('warning from git')
      end
    end

    context 'with out: option' do
      let(:out_io) { StringIO.new }
      let(:run_opts) { { out: out_io } }

      it 'forwards out: to ProcessExecuter' do
        expect(ProcessExecuter).to receive(:run) do |*_env_and_cmd, **opts|
          expect(opts[:out]).to be(out_io)
          mock_result
        end
        result
      end
    end

    context 'with in: option' do
      let(:in_io) { StringIO.new }
      let(:run_opts) { { in: in_io } }

      it 'forwards in: to ProcessExecuter' do
        expect(ProcessExecuter).to receive(:run) do |*_env_and_cmd, **opts|
          expect(opts[:in]).to be(in_io)
          mock_result
        end
        result
      end
    end

    context 'with chdir: option' do
      let(:run_args) { ['status'] }
      let(:run_opts) { { chdir: '/tmp' } }

      it 'forwards chdir to ProcessExecuter' do
        expect(ProcessExecuter).to receive(:run) do |*_env_and_cmd, **opts|
          expect(opts[:chdir]).to eq('/tmp')
          mock_result(command: %w[git status])
        end
        result
      end
    end

    context 'with timeout: option' do
      let(:run_args) { ['status'] }
      let(:run_opts) { { timeout: 5 } }

      it 'forwards timeout as timeout_after: to ProcessExecuter' do
        expect(ProcessExecuter).to receive(:run) do |*_env_and_cmd, **opts|
          expect(opts[:timeout_after]).to eq(5)
          mock_result(command: %w[git status])
        end
        result
      end
    end

    context 'with env: option' do
      let(:run_args) { ['status'] }
      let(:run_opts) { { env: { 'GIT_DIR' => '/tmp/repo' } } }

      it 'merges the per-call env into the instance env and passes it as the first argument' do
        expect(ProcessExecuter).to receive(:run) do |env_arg, *_cmd, **_opts|
          expect(env_arg).to include('GIT_DIR' => '/tmp/repo')
          mock_result(command: %w[git status])
        end
        result
      end
    end

    context 'with raise_on_failure: true (default)' do
      before do
        allow(ProcessExecuter).to receive(:run) do |*_args, err:, **_opts|
          err.write('fatal: not a git repository')
          mock_result(command: %w[git status], success?: false, exitstatus: 1)
        end
      end

      it 'raises FailedError when success? is false' do
        expect { described_instance.run('status') }
          .to raise_error(Git::FailedError, /git.*status/)
      end

      it 'attaches the result to the error' do
        expect { described_instance.run('status') }
          .to raise_error(Git::FailedError, /git.*status/) do |error|
            expect(error.result.status.success?).to be false
            expect(error.result.status.exitstatus).to eq(1)
            expect(error.result.stderr).to eq('fatal: not a git repository')
          end
      end
    end

    context 'with raise_on_failure: false' do
      let(:run_args) { ['status'] }
      let(:run_opts) { { raise_on_failure: false } }

      before do
        allow(ProcessExecuter).to receive(:run) do |*_args, err:, **_opts|
          err.write('fatal: not a git repository')
          mock_result(command: %w[git status], success?: false, exitstatus: 1)
        end
      end

      it 'returns a CommandLineResult without raising when success? is false' do
        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.success?).to be false
        expect(result.status.exitstatus).to eq(1)
        expect(result.stderr).to eq('fatal: not a git repository')
      end
    end

    context 'when command times out' do
      before do
        allow(ProcessExecuter).to receive(:run)
          .and_return(mock_result(command: %w[git status], success?: false, timed_out?: true))
      end

      it 'raises TimeoutError regardless of raise_on_failure' do
        expect { described_instance.run('status', raise_on_failure: false, timeout: 1) }
          .to raise_error(Git::TimeoutError, /timed out after/)
      end

      it 'attaches the result and timeout_duration to the error' do
        expect { described_instance.run('status', raise_on_failure: false, timeout: 1) }
          .to raise_error(Git::TimeoutError, /timed out after/) do |error|
            expect(error.result.status.timed_out?).to be true
            expect(error.timeout_duration).to eq(1)
          end
      end
    end

    context 'when command is signaled' do
      before do
        allow(ProcessExecuter).to receive(:run)
          .and_return(mock_result(command: %w[git status], success?: false, signaled?: true))
      end

      it 'raises SignaledError regardless of raise_on_failure' do
        expect { described_instance.run('status', raise_on_failure: false) }
          .to raise_error(Git::SignaledError, /git.*status/)
      end

      it 'attaches the result to the error' do
        expect { described_instance.run('status', raise_on_failure: false) }
          .to raise_error(Git::SignaledError, /git.*status/) do |error|
            expect(error.result.status.signaled?).to be true
          end
      end
    end

    context 'with an array element in the args list' do
      it 'raises ArgumentError with a descriptive message' do
        expect { described_instance.run([%w[bad arg]]) }
          .to raise_error(ArgumentError, /can not contain an array/)
      end
    end

    context 'with an unknown option' do
      it 'raises ArgumentError naming the unknown key' do
        expect { described_instance.run('status', unknown_option: true) }
          .to raise_error(ArgumentError, /Unknown options: unknown_option/)
      end
    end

    context 'when ProcessExecuter raises ArgumentError' do
      let(:pe_error) { ProcessExecuter::ArgumentError.new('bad spawn arg') }

      before do
        allow(ProcessExecuter).to receive(:run).and_raise(pe_error)
      end

      it 'translates to ArgumentError' do
        expect { described_instance.run('status') }
          .to raise_error(ArgumentError, 'bad spawn arg')
      end

      it 'sets the ProcessExecuter::ArgumentError as the cause' do
        expect { described_instance.run('status') }
          .to raise_error(ArgumentError, 'bad spawn arg') do |error|
            expect(error.cause).to be(pe_error)
          end
      end
    end

    context 'when ProcessExecuter raises ProcessIOError' do
      let(:original_error) { IOError.new('underlying io problem') }

      before do
        # Build a ProcessIOError that wraps original_error as its cause, mirroring
        # how ProcessExecuter raises it in production.
        pe_error = begin
          raise original_error
        rescue StandardError
          begin
            raise ProcessExecuter::ProcessIOError, 'pipe failure'
          rescue StandardError => e
            e
          end
        end
        allow(ProcessExecuter).to receive(:run).and_raise(pe_error)
      end

      it 'translates to Git::ProcessIOError' do
        expect { described_instance.run('status') }
          .to raise_error(Git::ProcessIOError, /pipe failure/)
      end

      it 'sets the original IO error as the cause' do
        # TruffleRuby < 25.0.0 has a bug where the cause is not set correctly
        # when an error is raised inside a rescue block.
        # See: https://github.com/truffleruby/truffleruby/issues/3831
        skip 'TruffleRuby < 25.0.0 does not correctly set error cause in rescue blocks' \
          if RUBY_ENGINE == 'truffleruby' && Gem::Version.new(RUBY_ENGINE_VERSION) < Gem::Version.new('25.0.0')

        expect { described_instance.run('status') }
          .to raise_error(Git::ProcessIOError, /pipe failure/) do |error|
            expect(error.cause).to be(original_error)
          end
      end
    end
  end
end
