# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Stashes do
  # These specs cover Git::Stashes with stubbed Git::Repository collaborators. The
  # real git path is exercised end-to-end by
  # spec/integration/git/repository/stashing_spec.rb.

  let(:execution_context) { instance_double(Git::ExecutionContext::Repository) }
  let(:repository) { Git::Repository.new(execution_context: execution_context) }

  let(:deprecation_message) do
    'Git::Stashes is deprecated and will be removed in v6.0.0. ' \
      'Use the Git::Repository stash methods (stash_infos, stash_push, stash_apply, stash_clear) ' \
      'and Git::StashInfo instead.'
  end

  # Git::Repository#stashes_all returns stashes in oldest-first order
  let(:mocked_stashes_all_result) do
    [
      [0, 'abc1234 Test'],
      [1, 'def5678 Work']
    ]
  end

  before do
    allow(Git::Deprecation).to receive(:warn)
    allow(repository).to receive(:stashes_all).and_return(mocked_stashes_all_result)
  end

  describe '#initialize' do
    it 'emits a deprecation warning via Git::Deprecation.warn' do
      expect(Git::Deprecation).to receive(:warn).with(deprecation_message)
      described_class.new(repository)
    end

    it 'loads stashes from the repository' do
      stashes = described_class.new(repository)
      expect(stashes.size).to eq(2)
    end

    it 'creates Stash objects from stash data' do
      stash_double = instance_double(Git::Stash, saved?: true)
      allow(Git::Stash).to receive(:new).and_return(stash_double)

      described_class.new(repository)

      expect(Git::Stash).to have_received(:new).with(repository, 'abc1234 Test', existing: true)
      expect(Git::Stash).to have_received(:new).with(repository, 'def5678 Work', existing: true)
    end

    context 'when stashes_all and Git::Stash.new themselves emit deprecation warnings' do
      let(:messages) { [] }

      # Route real warnings to a collector so the silence around the nested
      # deprecated calls is exercised instead of bypassed by the stubbed
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
        allow(repository).to receive(:stashes_all) do
          Git::Deprecation.warn('Git::Repository#stashes_all is deprecated')
          mocked_stashes_all_result
        end
      end

      it 'lets only the Git::Stashes warning escape' do
        described_class.new(repository)
        expect(messages).to contain_exactly(a_string_including('Git::Stashes is deprecated'))
      end
    end
  end

  describe '#all' do
    subject(:stashes) { described_class.new(repository) }

    it 'returns an array of [index, message] pairs' do
      result = stashes.all
      expect(result).to be_an(Array)
      expect(result).to eq(mocked_stashes_all_result)
    end

    it 'returns stashes in oldest-first order matching Git::Repository#stashes_all' do
      result = stashes.all
      # Index 0 should be the oldest stash (first in the reflog)
      # Index 1 should be the newer stash
      expect(result[0]).to eq([0, 'abc1234 Test'])
      expect(result[1]).to eq([1, 'def5678 Work'])
    end

    it 'returns fresh data from the repository on each call' do
      stashes

      new_data = [[0, 'new stash']]
      allow(repository).to receive(:stashes_all).and_return(new_data)

      result = stashes.all
      expect(result).to eq(new_data)
    end

    context 'when stashes_all itself emits a deprecation warning' do
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
        allow(repository).to receive(:stashes_all) do
          Git::Deprecation.warn('Git::Repository#stashes_all is deprecated')
          mocked_stashes_all_result
        end
      end

      it 'does not let the nested stashes_all warning escape' do
        stashes
        messages.clear

        stashes.all

        expect(messages).to be_empty
      end
    end
  end

  describe '#save' do
    subject(:stashes) { described_class.new(repository) }

    before do
      allow(Git::Stash).to receive(:new).and_return(instance_double(Git::Stash, saved?: true))
    end

    context 'when there are changes to stash' do
      let(:new_stash) { instance_double(Git::Stash, saved?: true) }

      before do
        allow(Git::Stash).to receive(:new).with(repository, 'WIP').and_return(new_stash)
      end

      it 'adds the new stash to the collection' do
        stashes.save('WIP')
        expect(stashes.size).to eq(3)
      end
    end

    context 'when there are no changes to stash' do
      let(:new_stash) { instance_double(Git::Stash, saved?: false) }

      before do
        allow(Git::Stash).to receive(:new).with(repository, 'WIP').and_return(new_stash)
      end

      it 'does not add anything to the collection' do
        stashes.save('WIP')
        expect(stashes.size).to eq(2)
      end
    end

    context 'when the Git::Stash it builds emits a deprecation warning' do
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
        allow(Git::Stash).to receive(:new).with(repository, 'WIP') do
          Git::Deprecation.warn('Git::Stash is deprecated')
          instance_double(Git::Stash, saved?: true)
        end
        stashes
      end

      it 'does not let the nested Git::Stash warning escape' do
        expect { stashes.save('WIP') }.not_to(change { messages.size })
      end
    end
  end

  describe '#each' do
    subject(:stashes) { described_class.new(repository) }

    before do
      allow(Git::Stash).to receive(:new) do |_base, message, **_kwargs|
        instance_double(Git::Stash, saved?: true, message: message)
      end
    end

    it 'yields Git::Stash objects' do
      yielded = stashes.map { |s| s }

      expect(yielded).to all(be_a(RSpec::Mocks::InstanceVerifyingDouble))
      expect(yielded.size).to eq(2)
    end

    it 'iterates stashes in newest-first order' do
      yielded_messages = stashes.map(&:message)

      # Should yield newest stash first (stash@{0}), then oldest
      expect(yielded_messages[0]).to eq('def5678 Work')
      expect(yielded_messages[1]).to eq('abc1234 Test')
    end

    it 'returns an enumerator when no block given' do
      expect(stashes.each).to be_an(Enumerator)
    end
  end

  describe '#[]' do
    subject(:stashes) { described_class.new(repository) }

    before do
      allow(Git::Stash).to receive(:new) do |_base, message, **_kwargs|
        instance_double(Git::Stash, saved?: true, message: message)
      end
    end

    it 'returns stashes in newest-first order' do
      expect(stashes[0].message).to eq('def5678 Work')
      expect(stashes[1].message).to eq('abc1234 Test')
    end

    it 'returns nil for out of bounds index' do
      expect(stashes[99]).to be_nil
    end

    it 'converts string index to integer' do
      expect(stashes['0'].message).to eq('def5678 Work')
    end
  end

  describe '#size' do
    subject(:stashes) { described_class.new(repository) }

    before do
      allow(Git::Stash).to receive(:new).and_return(instance_double(Git::Stash, saved?: true))
    end

    it 'returns the number of stashes' do
      expect(stashes.size).to eq(2)
    end
  end

  describe '#clear' do
    subject(:stashes) { described_class.new(repository) }

    before do
      allow(Git::Stash).to receive(:new).and_return(instance_double(Git::Stash, saved?: true))
      allow(repository).to receive(:stash_clear)
    end

    it 'clears all stashes by calling stash_clear on the repository' do
      stashes.clear
      expect(repository).to have_received(:stash_clear)
      expect(stashes.size).to eq(0)
    end
  end

  describe '#apply' do
    subject(:stashes) { described_class.new(repository) }

    before do
      allow(Git::Stash).to receive(:new).and_return(instance_double(Git::Stash, saved?: true))
      allow(repository).to receive(:stash_apply)
    end

    it 'applies the stash at the given index' do
      stashes.apply(1)
      expect(repository).to have_received(:stash_apply).with(1)
    end

    it 'applies the latest stash when no index given' do
      stashes.apply
      expect(repository).to have_received(:stash_apply).with(nil)
    end
  end
end
