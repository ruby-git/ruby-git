# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Stashes do
  let(:base) { double('Git::Base') }
  let(:lib) { double('Git::Lib') }

  # Git::Lib#stashes_all returns stashes in oldest-first order
  let(:mocked_stashes_all_result) do
    [
      [0, 'abc1234 Test'],
      [1, 'def5678 Work']
    ]
  end

  before do
    allow(base).to receive(:lib).and_return(lib)
    allow(lib).to receive(:stashes_all).and_return(mocked_stashes_all_result)
  end

  describe '#initialize' do
    it 'loads stashes from the repository' do
      stashes = described_class.new(base)
      expect(stashes.size).to eq(2)
    end

    it 'creates Stash objects from stash data' do
      stash_double = double('Stash', saved?: true)
      allow(Git::Stash).to receive(:new).and_return(stash_double)

      described_class.new(base)

      expect(Git::Stash).to have_received(:new).with(base, 'abc1234 Test', existing: true)
      expect(Git::Stash).to have_received(:new).with(base, 'def5678 Work', existing: true)
    end
  end

  describe '#all' do
    subject(:stashes) { described_class.new(base) }

    it 'returns an array of [index, message] pairs' do
      result = stashes.all
      expect(result).to be_an(Array)
      expect(result).to eq(mocked_stashes_all_result)
    end

    it 'returns stashes in oldest-first order matching Git::Lib#stashes_all' do
      result = stashes.all
      # Index 0 should be the oldest stash (first in the reflog)
      # Index 1 should be the newer stash
      expect(result[0]).to eq([0, 'abc1234 Test'])
      expect(result[1]).to eq([1, 'def5678 Work'])
    end

    it 'returns fresh data from the repository' do
      stashes

      new_data = [[0, 'new stash']]
      allow(lib).to receive(:stashes_all).and_return(new_data)

      result = stashes.all
      expect(result).to eq(new_data)
    end
  end

  describe '#each' do
    subject(:stashes) { described_class.new(base) }

    before do
      allow(Git::Stash).to receive(:new).and_wrap_original do |_method, _base, message, **_kwargs|
        instance_double('Git::Stash', saved?: true, message: message)
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
    subject(:stashes) { described_class.new(base) }

    before do
      allow(Git::Stash).to receive(:new).and_wrap_original do |_method, _base, message, **_kwargs|
        instance_double('Git::Stash', saved?: true, message: message)
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
    subject(:stashes) { described_class.new(base) }

    before do
      allow(Git::Stash).to receive(:new).and_return(double('Stash', saved?: true))
    end

    it 'returns the number of stashes' do
      expect(stashes.size).to eq(2)
    end
  end

  describe '#clear' do
    subject(:stashes) { described_class.new(base) }

    before do
      allow(Git::Stash).to receive(:new).and_return(double('Stash', saved?: true))
      allow(lib).to receive(:stash_clear)
    end

    it 'clears all stashes' do
      stashes.clear
      expect(lib).to have_received(:stash_clear)
      expect(stashes.size).to eq(0)
    end
  end

  describe '#apply' do
    subject(:stashes) { described_class.new(base) }

    before do
      allow(Git::Stash).to receive(:new).and_return(double('Stash', saved?: true))
      allow(lib).to receive(:stash_apply)
    end

    it 'applies the stash at the given index' do
      stashes.apply(1)
      expect(lib).to have_received(:stash_apply).with(1)
    end

    it 'applies the latest stash when no index given' do
      stashes.apply
      expect(lib).to have_received(:stash_apply).with(nil)
    end
  end
end
