# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git do
  describe '.git_version' do
    let(:binary_path) { Git::Base.config.binary_path }
    let(:context) { instance_double(Git::ExecutionContext::Global) }
    let(:version_cmd) { instance_double(Git::Commands::Version) }

    before do
      Git::Lib.clear_git_version_cache
      allow(Git::ExecutionContext::Global).to receive(:new).and_return(context)
      allow(Git::Commands::Version).to receive(:new).with(context).and_return(version_cmd)
    end

    context 'when called with no argument (default binary)' do
      before do
        allow(version_cmd).to receive(:call).and_return(command_result('git version 2.42.0'))
      end

      it 'returns a Git::Version' do
        version = described_class.git_version

        expect(version).to be_a(Git::Version)
      end
    end

    context 'when called with an explicit binary_path' do
      let(:explicit_path) { '/usr/local/bin/git2' }
      let(:explicit_context) { instance_double(Git::ExecutionContext::Global) }
      let(:explicit_cmd) { instance_double(Git::Commands::Version) }

      before do
        allow(Git::ExecutionContext::Global).to receive(:new)
          .with(binary_path: explicit_path).and_return(explicit_context)
        allow(Git::Commands::Version).to receive(:new).with(explicit_context).and_return(explicit_cmd)
        allow(explicit_cmd).to receive(:call).and_return(command_result('git version 2.42.0'))
      end

      it 'returns a Git::Version for the specified binary' do
        version = described_class.git_version(explicit_path)

        expect(version).to be_a(Git::Version)
        expect(explicit_cmd).to have_received(:call).once
      end

      it 'caches the result per binary path (second call does not re-shell)' do
        allow(explicit_cmd).to receive(:call).and_return(command_result('git version 2.40.0'))

        described_class.git_version(explicit_path)
        described_class.git_version(explicit_path)

        expect(explicit_cmd).to have_received(:call).once
      end

      it 'caches independently from the default binary path' do
        allow(version_cmd).to receive(:call).and_return(command_result('git version 2.42.0'))

        described_class.git_version
        described_class.git_version(explicit_path)

        expect(version_cmd).to have_received(:call).once
        expect(explicit_cmd).to have_received(:call).once
      end
    end

    context 'when the binary is not found' do
      before do
        allow(Git::ExecutionContext::Global).to receive(:new).and_call_original
        allow(Git::Commands::Version).to receive(:new).and_call_original
        allow(ProcessExecuter).to receive(:run_with_capture) do
          raise Errno::ENOENT, 'git'
        rescue Errno::ENOENT
          raise ProcessExecuter::SpawnError, 'Failed to spawn process: No such file or directory - git'
        end
      end

      it 'raises Git::Error with Errno::ENOENT as cause' do
        expect { described_class.git_version }.to raise_error(Git::Error) do |error|
          expect(error.cause).to be_a(Errno::ENOENT)
        end
      end
    end

    context 'when the binary exists but is not executable' do
      before do
        allow(Git::ExecutionContext::Global).to receive(:new).and_call_original
        allow(Git::Commands::Version).to receive(:new).and_call_original
        allow(ProcessExecuter).to receive(:run_with_capture) do
          raise Errno::EACCES, 'git'
        rescue Errno::EACCES
          raise ProcessExecuter::SpawnError, 'Failed to spawn process: Permission denied - git'
        end
      end

      it 'raises Git::Error with Errno::EACCES as cause' do
        expect { described_class.git_version }.to raise_error(Git::Error) do |error|
          expect(error.cause).to be_a(Errno::EACCES)
        end
      end
    end

    context 'when the binary exits with a non-zero status' do
      before do
        allow(version_cmd).to receive(:call).and_raise(
          Git::FailedError.new(command_result('', stderr: 'git: command not found', exitstatus: 1))
        )
      end

      it 'raises Git::FailedError' do
        expect { described_class.git_version }.to raise_error(Git::FailedError)
      end
    end

    context 'when the version cannot be parsed' do
      before do
        allow(version_cmd).to receive(:call).and_return(command_result('not a version string'))
      end

      it 'raises Git::UnexpectedResultError' do
        expect { described_class.git_version }.to raise_error(Git::UnexpectedResultError)
      end
    end
  end

  describe '.binary_version' do
    before do
      allow(Git::Deprecation).to receive(:warn)
      allow(Git).to receive(:git_version).and_return(Git::Version.new(2, 42, 0))
    end

    it 'emits a deprecation warning' do
      described_class.binary_version

      expect(Git::Deprecation).to have_received(:warn).with(
        'Git.binary_version is deprecated and will be removed in 6.0. ' \
        'Use Git.git_version instead, which returns a Git::Version ' \
        '(not an Array). For the legacy array shape, call: Git.git_version.to_a. ' \
        'The optional binary_path argument is preserved: Git.git_version(binary_path).'
      ).once
    end

    it 'emits exactly one deprecation warning per call' do
      described_class.binary_version

      expect(Git::Deprecation).to have_received(:warn).exactly(1).time
    end

    it 'still returns an Array of integers' do
      expect(described_class.binary_version).to eq([2, 42, 0])
    end
  end
end

RSpec.describe Git::Base do
  describe '.binary_version' do
    let(:binary_path) { described_class.config.binary_path }

    before do
      allow(Git::Deprecation).to receive(:warn)
      allow(Git).to receive(:git_version).and_return(Git::Version.new(2, 42, 0))
    end

    it 'emits a deprecation warning' do
      described_class.binary_version(binary_path)

      expect(Git::Deprecation).to have_received(:warn).with(
        'Git::Base.binary_version is deprecated and will be removed in 6.0. ' \
        'Use Git.git_version instead, which returns a Git::Version ' \
        '(not an Array). For the legacy array shape, call: Git.git_version.to_a'
      ).once
    end

    it 'emits exactly one deprecation warning per call' do
      described_class.binary_version(binary_path)

      expect(Git::Deprecation).to have_received(:warn).exactly(1).time
    end

    it 'still returns an Array of integers' do
      expect(described_class.binary_version(binary_path)).to eq([2, 42, 0])
    end
  end
end
