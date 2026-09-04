# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Stash do
  # These specs cover Git::Stash with stubbed Git::Repository collaborators. The
  # real git path is exercised end-to-end by
  # spec/integration/git/repository/stashing_spec.rb.

  let(:execution_context) { instance_double(Git::ExecutionContext::Repository) }
  let(:repository) { Git::Repository.new(execution_context: execution_context) }

  let(:deprecation_message) do
    'Git::Stash is deprecated and will be removed in v6.0.0. ' \
      'Use the Git::Repository stash methods (stash_push, stash_infos, stash_apply) ' \
      'and Git::StashInfo instead.'
  end

  before { allow(Git::Deprecation).to receive(:warn) }

  describe '#initialize' do
    context 'when existing: false (default)' do
      before do
        allow(repository).to receive(:stash_save).with('test message').and_return(true)
      end

      it 'emits a deprecation warning via Git::Deprecation.warn' do
        expect(Git::Deprecation).to receive(:warn).with(deprecation_message)
        described_class.new(repository, 'test message')
      end

      it 'calls stash_save on the repository with the message' do
        expect(repository).to receive(:stash_save).with('test message')
        described_class.new(repository, 'test message')
      end

      context 'when stash_save itself emits a deprecation warning' do
        let(:messages) { [] }

        # Route real warnings to a collector so the silence around the nested
        # deprecated call is exercised instead of bypassed by the stubbed
        # Git::Deprecation.warn
        around do |example|
          original_behavior = Git::Deprecation.behavior
          Git::Deprecation.behavior = ->(message, *) { messages << message }
          example.run
        ensure
          Git::Deprecation.behavior = original_behavior
        end

        before do
          allow(Git::Deprecation).to receive(:warn).and_call_original
          allow(repository).to receive(:stash_save).with('test message') do
            Git::Deprecation.warn('Git::Repository#stash_save is deprecated')
            true
          end
        end

        it 'lets only the Git::Stash warning escape' do
          described_class.new(repository, 'test message')
          expect(messages).to contain_exactly(a_string_including('Git::Stash is deprecated'))
        end
      end
    end

    context 'when existing: true' do
      it 'emits a deprecation warning via Git::Deprecation.warn' do
        expect(Git::Deprecation).to receive(:warn).with(deprecation_message)
        described_class.new(repository, 'test message', existing: true)
      end

      it 'does not call stash_save' do
        expect(repository).not_to receive(:stash_save)
        described_class.new(repository, 'test message', existing: true)
      end
    end
  end

  describe '#save' do
    subject(:stash) { described_class.new(repository, 'test message', existing: true) }

    it 'calls stash_save on the repository and returns its result' do
      expect(repository).to receive(:stash_save).with('test message').and_return(true)
      expect(stash.save).to be(true)
    end

    context 'when stash_save itself emits a deprecation warning' do
      let(:messages) { [] }

      # Route real warnings to a collector so the silence around the nested
      # deprecated call is exercised instead of bypassed by the stubbed
      # Git::Deprecation.warn
      around do |example|
        original_behavior = Git::Deprecation.behavior
        Git::Deprecation.behavior = ->(message, *) { messages << message }
        example.run
      ensure
        Git::Deprecation.behavior = original_behavior
      end

      before do
        allow(Git::Deprecation).to receive(:warn).and_call_original
        allow(repository).to receive(:stash_save).with('test message') do
          Git::Deprecation.warn('Git::Repository#stash_save is deprecated')
          true
        end
        stash
      end

      it 'does not let the nested stash_save warning escape' do
        expect { stash.save }.not_to(change { messages.size })
      end
    end
  end

  describe '#saved?' do
    context 'when stash_save returns true (changes saved)' do
      subject(:stash) { described_class.new(repository, 'test message') }

      before do
        allow(repository).to receive(:stash_save).with('test message').and_return(true)
      end

      it 'returns true' do
        expect(stash.saved?).to be(true)
      end
    end

    context 'when stash_save returns false (no changes to save)' do
      subject(:stash) { described_class.new(repository, 'test message') }

      before do
        allow(repository).to receive(:stash_save).with('test message').and_return(false)
      end

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
    subject(:stash) { described_class.new(repository, 'my message', existing: true) }

    it 'returns the stash message' do
      expect(stash.message).to eq('my message')
    end
  end

  describe '#to_s' do
    subject(:stash) { described_class.new(repository, 'my message', existing: true) }

    it 'returns the stash message' do
      expect(stash.to_s).to eq('my message')
    end
  end
end
