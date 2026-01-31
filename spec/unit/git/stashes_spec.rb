# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Stashes do
  let(:base) { double('Git::Base') }
  let(:lib) { double('Git::Lib') }
  let(:stash_info_data) do
    [
      instance_double('Git::StashInfo', index: 0, message: 'abc1234 Test'),
      instance_double('Git::StashInfo', index: 1, message: 'def5678 Work')
    ]
  end
  let(:stash_legacy_data) do
    [
      [0, 'abc1234 Test'],
      [1, 'def5678 Work']
    ]
  end

  before do
    allow(base).to receive(:lib).and_return(lib)
    allow(lib).to receive(:stashes_list).and_return(stash_info_data)
    allow(lib).to receive(:stashes_all).and_return(stash_legacy_data)
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

      expect(Git::Stash).to have_received(:new).with(base, 'abc1234 Test', save: true)
      expect(Git::Stash).to have_received(:new).with(base, 'def5678 Work', save: true)
    end

    it 'maintains stash ordering where stashes[0] is stash@{0}' do
      stashes = described_class.new(base)
      # stash_info_data is [StashInfo(0, 'abc1234 Test'), StashInfo(1, 'def5678 Work')]
      # stashes[0] should correspond to stash@{0} (the first/latest stash)
      expect(stashes[0].message).to eq('abc1234 Test')
      expect(stashes[1].message).to eq('def5678 Work')
    end
  end

  describe '#all' do
    subject(:stashes) { described_class.new(base) }

    it 'returns an array of StashInfo objects' do
      result = stashes.all
      expect(result).to be_an(Array)
      expect(result).to eq(stash_info_data)
    end

    it 'returns fresh data from the repository' do
      stashes

      new_info = instance_double('Git::StashInfo', index: 0, message: 'new stash')
      allow(lib).to receive(:stashes_list).and_return([new_info])

      result = stashes.all
      expect(result).to eq([new_info])
    end
  end

  describe '#all_legacy' do
    subject(:stashes) { described_class.new(base) }

    it 'returns an array of [index, message] pairs and emits a deprecation warning' do
      result = nil
      expect { result = stashes.all_legacy }.to output(/DEPRECATION/).to_stderr
      expect(result).to be_an(Array)
      expect(result).to eq(stash_legacy_data)
    end
  end

  describe '#each' do
    subject(:stashes) { described_class.new(base) }

    before do
      allow(Git::Stash).to receive(:new).and_wrap_original do |_method, _base, message, **_opts|
        instance_double('Git::Stash', saved?: true, message: message)
      end
    end

    it 'yields Git::Stash objects' do
      yielded = stashes.map { |s| s }

      expect(yielded).to all(be_a(RSpec::Mocks::InstanceVerifyingDouble))
      expect(yielded.size).to eq(2)
    end

    it 'returns an enumerator when no block given' do
      expect(stashes.each).to be_an(Enumerator)
    end
  end

  describe '#[]' do
    subject(:stashes) { described_class.new(base) }

    before do
      allow(Git::Stash).to receive(:new).and_wrap_original do |_method, _base, message, **_opts|
        instance_double('Git::Stash', saved?: true, message: message)
      end
    end

    it 'returns the stash at the given index' do
      expect(stashes[0]).not_to be_nil
      expect(stashes[1]).not_to be_nil
    end

    it 'returns nil for out of bounds index' do
      expect(stashes[99]).to be_nil
    end

    it 'converts string index to integer' do
      expect(stashes['0']).not_to be_nil
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
