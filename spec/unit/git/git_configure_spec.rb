# frozen_string_literal: true

require 'spec_helper'

# These specs verify that Git.configure, Git.config, Git.git_version, and
# Git.binary_version resolve global config through Git::Config.instance and NOT
# through Git::Base.config (Step C1b of the architectural redesign).
#
RSpec.describe Git do
  describe '.config' do
    it 'returns Git::Config.instance' do
      expect(described_class.config).to be(Git::Config.instance)
    end

    it 'does NOT route through Git::Base.config' do
      expect(Git::Base).not_to receive(:config)
      described_class.config
    end
  end

  describe '.configure' do
    it 'yields Git::Config.instance' do
      expect { |b| described_class.configure(&b) }.to yield_with_args(Git::Config.instance)
    end

    it 'returns nil (void semantics)' do
      expect(described_class.configure { |_c| 'ignored' }).to be_nil
    end

    it 'does NOT route through Git::Base.config' do
      expect(Git::Base).not_to receive(:config)
      described_class.configure { |_c| nil }
    end
  end

  describe '.git_version default binary path' do
    before { Git::Lib.clear_git_version_cache }

    it 'uses Git::Config.instance.binary_path (not Git::Base.config) when no arg given' do
      expected_path = Git::Config.instance.binary_path
      allow(Git::Lib).to receive(:cached_git_version).and_return(Git::Version.new(2, 42, 0))
      expect(Git::Base).not_to receive(:config)
      described_class.git_version
      expect(Git::Lib).to have_received(:cached_git_version).with(expected_path)
    end
  end

  describe '.binary_version' do
    before do
      allow(Git::Deprecation).to receive(:warn)
      allow(Git).to receive(:git_version).and_return(Git::Version.new(2, 42, 0))
    end

    it 'does NOT route through Git::Base.config for the default binary path' do
      expect(Git::Base).not_to receive(:config)
      described_class.binary_version
    end
  end
end
