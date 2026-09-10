# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git do
  describe '.configure_deprecation_behavior' do
    subject { described_class.send(:configure_deprecation_behavior, deprecation, behavior) }

    let(:deprecation) { instance_double(ActiveSupport::Deprecation) }

    context 'when behavior is nil' do
      let(:behavior) { nil }

      it 'leaves the deprecation instance unchanged' do
        expect(deprecation).not_to receive(:behavior=)
        subject
      end
    end

    context 'when behavior is a valid name' do
      let(:behavior) { 'silence' }

      it 'sets the deprecation behavior to the corresponding symbol' do
        expect(deprecation).to receive(:behavior=).with(:silence)
        subject
      end
    end

    context 'when behavior has surrounding whitespace' do
      let(:behavior) { "  silence\n" }

      it 'strips the whitespace before applying the behavior' do
        expect(deprecation).to receive(:behavior=).with(:silence)
        subject
      end
    end

    context 'when behavior is invalid' do
      let(:behavior) { 'silent' }

      it 'raises an ArgumentError listing the allowed behaviors' do
        allowed = ActiveSupport::Deprecation::DEFAULT_BEHAVIORS.keys.join(', ')

        expect { subject }.to raise_error(
          ArgumentError,
          %(Invalid GIT_DEPRECATION_BEHAVIOR="silent"; expected one of: #{allowed})
        )
      end
    end
  end

  describe '.export' do
    subject(:result) { described_class.export(repository_url, directory, options) }

    let(:repository_url) { 'https://example.com/repo.git' }
    let(:directory) { '/tmp/example' }
    let(:options) { {} }
    let(:repo) { instance_double(Git::Repository, dir: Pathname.new(directory)) }

    before do
      allow(described_class).to receive(:clone).and_return(repo)
      allow(FileUtils).to receive(:rm_r)
    end

    it 'clones the repository with depth: 1 merged into the given options' do
      expect(described_class).to receive(:clone).with(repository_url, directory, { depth: 1 }).and_return(repo)
      result
    end

    it 'does not emit a deprecation warning' do
      expect(Git::Deprecation).not_to receive(:warn)
      result
    end

    it 'removes the .git directory from the cloned repository' do
      expect(FileUtils).to receive(:rm_r).with(File.join(directory, '.git'))
      result
    end

    context 'when options include :remote' do
      let(:options) { { remote: 'upstream' } }

      before { allow(Git::Deprecation).to receive(:warn) }

      it 'emits a deprecation warning saying the option is ignored and should be deleted' do
        expect(Git::Deprecation).to receive(:warn).with(
          'The :remote option to Git.export is ignored, is deprecated, and will be removed in a future ' \
          'major release. Delete it from the call.'
        )
        result
      end

      it 'removes :remote before passing options to clone' do
        expect(described_class).to receive(:clone).with(repository_url, directory, { depth: 1 }).and_return(repo)
        result
      end
    end

    context 'when options include :branch' do
      let(:options) { { branch: 'v1.0.0' } }

      it 'forwards :branch to clone so git resolves the branch or tag' do
        expect(described_class).to receive(:clone)
          .with(repository_url, directory, { depth: 1, branch: 'v1.0.0' })
          .and_return(repo)
        result
      end
    end
  end
end
