# frozen_string_literal: true

require 'spec_helper'

# These specs verify that Git.configure, Git.config, Git.git_version, and
# Git.binary_version resolve global config through Git::Config.instance.
# They also verify that Git extends Git::Configuring for structured config access.
#
RSpec.describe Git do
  describe 'Git::Configuring mixin' do
    it 'extends Git with Git::Configuring so all config_* class methods are available' do
      expect(described_class.singleton_class.ancestors).to include(Git::Configuring)
    end

    describe 'assert_valid_scope! rejects repository-specific scopes' do
      it 'raises ArgumentError for local: scope' do
        expect { described_class.config_get('user.name', local: true) }
          .to raise_error(ArgumentError, /local/)
      end

      it 'raises ArgumentError for worktree: scope' do
        expect { described_class.config_get('user.name', worktree: true) }
          .to raise_error(ArgumentError, /worktree/)
      end

      it 'raises ArgumentError for blob: scope' do
        expect { described_class.config_get('user.name', blob: 'HEAD:.gitconfig') }
          .to raise_error(ArgumentError, /blob/)
      end
    end

    describe 'assert_valid_scope! allows non-repository scopes' do
      let(:get_command) { instance_double(Git::Commands::ConfigOptionSyntax::Get) }

      before do
        allow(Git::Commands::ConfigOptionSyntax::Get)
          .to receive(:new).with(instance_of(Git::ExecutionContext::Global)).and_return(get_command)
        allow(get_command).to receive(:call).and_return(command_result(''))
      end

      it 'allows global: scope' do
        expect { described_class.config_get('user.name', global: true) }.not_to raise_error
      end

      it 'allows system: scope' do
        expect { described_class.config_get('user.name', system: true) }.not_to raise_error
      end

      it 'allows file: scope' do
        expect { described_class.config_get('user.name', file: '/tmp/config') }.not_to raise_error
      end
    end
  end

  describe '.config' do
    it 'returns Git::Config.instance' do
      expect(described_class.config).to be(Git::Config.instance)
    end
  end

  describe '.configure' do
    it 'yields Git::Config.instance' do
      expect { |b| described_class.configure(&b) }.to yield_with_args(Git::Config.instance)
    end

    it 'returns nil (void semantics)' do
      expect(described_class.configure { |_c| 'ignored' }).to be_nil
    end
  end

  describe '.git_version default binary path' do
    before { Git.clear_git_version_cache }

    it 'uses Git::Config.instance.binary_path when no arg given' do
      expected_path = Git::Config.instance.binary_path
      allow(Git).to receive(:cached_git_version).and_return(Git::Version.new(2, 42, 0))
      described_class.git_version
      expect(Git).to have_received(:cached_git_version).with(expected_path)
    end
  end

  describe '.binary_version' do
    before do
      allow(Git::Deprecation).to receive(:warn)
      allow(Git).to receive(:git_version).and_return(Git::Version.new(2, 42, 0))
    end

    it 'delegates to Git.git_version for the default binary path' do
      result = described_class.binary_version
      expect(Git).to have_received(:git_version)
      expect(result).to eq([2, 42, 0])
    end
  end
end
