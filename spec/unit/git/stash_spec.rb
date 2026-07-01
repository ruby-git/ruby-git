# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Stash do
  # Git::Stash accepts either Git::Repository (new form) or Git::Base (legacy) as base.
  # These specs cover the Git::Repository path with stubbed collaborators; the
  # Git::Base path is exercised end-to-end by
  # spec/integration/git/repository/stashing_spec.rb.

  let(:execution_context) { instance_double(Git::ExecutionContext::Repository) }
  let(:repository) { Git::Repository.new(execution_context: execution_context) }

  describe '#initialize' do
    context 'when base is Git::Repository and existing: false (default)' do
      before do
        allow(repository).to receive(:stash_save).with('test message').and_return(true)
      end

      it 'calls stash_save on the repository with the message' do
        expect(repository).to receive(:stash_save).with('test message')
        described_class.new(repository, 'test message')
      end
    end

    context 'when base is Git::Repository and existing: true' do
      it 'does not call stash_save' do
        expect(repository).not_to receive(:stash_save)
        described_class.new(repository, 'test message', existing: true)
      end
    end
  end

  describe '#saved?' do
    context 'when base is Git::Repository and stash_save returns true (changes saved)' do
      before do
        allow(repository).to receive(:stash_save).with('test message').and_return(true)
      end

      subject(:stash) { described_class.new(repository, 'test message') }

      it 'returns true' do
        expect(stash.saved?).to be(true)
      end
    end

    context 'when base is Git::Repository and stash_save returns false (no changes to save)' do
      before do
        allow(repository).to receive(:stash_save).with('test message').and_return(false)
      end

      subject(:stash) { described_class.new(repository, 'test message') }

      it 'returns false' do
        expect(stash.saved?).to be(false)
      end
    end

    context 'when existing: true (stash was pre-existing, save not called)' do
      subject(:stash) { described_class.new(repository, 'test message', existing: true) }

      it 'returns nil' do
        expect(stash.saved?).to be_nil
      end
    end
  end

  describe '#message' do
    before do
      allow(repository).to receive(:stash_save).with('my message').and_return(true)
    end

    subject(:stash) { described_class.new(repository, 'my message') }

    it 'returns the stash message' do
      expect(stash.message).to eq('my message')
    end
  end

  describe '#to_s' do
    before do
      allow(repository).to receive(:stash_save).with('my message').and_return(true)
    end

    subject(:stash) { described_class.new(repository, 'my message') }

    it 'returns the stash message' do
      expect(stash.to_s).to eq('my message')
    end
  end
end
