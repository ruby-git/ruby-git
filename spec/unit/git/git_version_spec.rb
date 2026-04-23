# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git do
  describe '.git_version' do
    let(:binary_path) { Git::Base.config.binary_path }
    let(:success_status) { instance_double(Process::Status, success?: true) }
    let(:failure_status) { instance_double(Process::Status, success?: false) }

    before { Git::Lib.clear_git_version_cache }

    context 'when called with no argument (default binary)' do
      before do
        allow(Open3).to receive(:capture2e).with(binary_path, 'version')
                                           .and_return(['git version 2.42.0', success_status])
      end

      it 'returns a Git::Version' do
        version = described_class.git_version

        expect(version).to be_a(Git::Version)
      end
    end

    context 'when called with an explicit binary_path' do
      let(:explicit_path) { '/usr/local/bin/git2' }

      it 'returns a Git::Version for the specified binary' do
        allow(Open3).to receive(:capture2e).with(explicit_path, 'version')
                                           .and_return(['git version 2.42.0', success_status])

        version = described_class.git_version(explicit_path)

        expect(version).to be_a(Git::Version)
        expect(Open3).to have_received(:capture2e).with(explicit_path, 'version').once
      end

      it 'caches the result per binary path (second call does not re-shell)' do
        allow(Open3).to receive(:capture2e).with(explicit_path, 'version')
                                           .and_return(['git version 2.40.0', success_status])

        described_class.git_version(explicit_path)
        described_class.git_version(explicit_path)

        expect(Open3).to have_received(:capture2e).once
      end

      it 'caches independently from the default binary path' do
        allow(Open3).to receive(:capture2e).with(binary_path, 'version')
                                           .and_return(['git version 2.42.0', success_status])
        allow(Open3).to receive(:capture2e).with(explicit_path, 'version')
                                           .and_return(['git version 2.40.0', success_status])

        described_class.git_version
        described_class.git_version(explicit_path)

        expect(Open3).to have_received(:capture2e).with(binary_path, 'version').once
        expect(Open3).to have_received(:capture2e).with(explicit_path, 'version').once
      end
    end

    context 'when the binary is not found' do
      before do
        allow(Open3).to receive(:capture2e).and_raise(Errno::ENOENT)
      end

      it 'raises Git::Error' do
        expect { described_class.git_version }.to raise_error(Git::Error, /Git binary not found/)
      end
    end

    context 'when the binary exists but is not executable' do
      before do
        allow(Open3).to receive(:capture2e).and_raise(Errno::EACCES)
      end

      it 'raises Git::Error' do
        expect { described_class.git_version }.to raise_error(Git::Error, /Failed to execute git binary/)
      end
    end

    context 'when the binary exits with a non-zero status' do
      before do
        allow(Open3).to receive(:capture2e).and_return(['git: command not found', failure_status])
      end

      it 'raises Git::Error' do
        expect { described_class.git_version }.to raise_error(Git::Error, /Failed to run/)
      end
    end

    context 'when the version cannot be parsed' do
      before do
        allow(Open3).to receive(:capture2e).and_return(['not a version string', success_status])
      end

      it 'raises Git::Error' do
        expect { described_class.git_version }.to raise_error(Git::Error, /Unable to parse git version/)
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
