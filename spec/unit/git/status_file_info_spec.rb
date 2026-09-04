# frozen_string_literal: true

require 'spec_helper'
require 'git/status_file_info'

RSpec.describe Git::StatusFileInfo do
  let(:sha_head) { '1111111111111111111111111111111111111111' }
  let(:sha_index) { '2222222222222222222222222222222222222222' }
  let(:index_status) { '.' }
  let(:worktree_status) { '.' }
  let(:original_path) { nil }
  let(:rename_score) { nil }
  let(:unmerged_stages) { nil }
  let(:default_attrs) do
    {
      path: 'lib/foo.rb',
      index_status: index_status,
      worktree_status: worktree_status,
      submodule: 'N...',
      mode_head: '100644',
      mode_index: '100644',
      mode_worktree: '100644',
      sha_head: sha_head,
      sha_index: sha_index,
      original_path: original_path,
      rename_score: rename_score,
      unmerged_stages: unmerged_stages
    }
  end
  let(:described_instance) { described_class.new(**default_attrs) }

  describe '#initialize' do
    subject(:instance) { described_instance }

    it 'stores all members' do
      expect(instance).to have_attributes(**default_attrs)
    end

    it 'creates an immutable object' do
      expect(instance).to be_frozen
      expect { instance.path = 'other.rb' }.to raise_error(NoMethodError, /path=/)
    end

    it 'stores frozen copies of the string members without freezing the strings given' do
      path = +'lib/foo.rb'
      instance = described_class.new(**default_attrs, path: path)
      expect(instance.path).to eq(path)
      expect(instance.path).to be_frozen
      expect(path).not_to be_frozen
    end

    it 'rejects mutation of its string members' do
      expect { instance.path << 'x' }.to raise_error(FrozenError)
    end

    context 'when unmerged_stages is given' do
      let(:index_status) { 'U' }
      let(:worktree_status) { 'U' }
      let(:unmerged_stages) { { 1 => { mode: +'100644', sha: +sha_head } } }

      it 'stores a deeply frozen copy of the stage data' do
        stages = instance.unmerged_stages
        expect(stages).to eq(unmerged_stages)
        expect(stages).to be_frozen
        expect(stages.values).to all(be_frozen)
        expect(stages.values.flat_map(&:values)).to all(be_frozen)
        expect { stages[1][:mode] << 'x' }.to raise_error(FrozenError)
      end

      it 'does not freeze the hash the caller passed in' do
        instance
        expect(unmerged_stages).not_to be_frozen
        expect(unmerged_stages[1]).not_to be_frozen
        expect(unmerged_stages[1][:mode]).not_to be_frozen
      end
    end

    it 'compares equal to another instance with the same values' do
      expect(instance).to eq(described_class.new(**default_attrs))
    end

    it 'does not compare equal to an instance with different values' do
      expect(instance).not_to eq(described_class.new(**default_attrs, path: 'lib/bar.rb'))
    end
  end

  describe '#untracked?' do
    subject(:result) { described_instance.untracked? }

    context 'when the entry is untracked (both status characters are ?)' do
      let(:index_status) { '?' }
      let(:worktree_status) { '?' }

      it { is_expected.to be(true) }
    end

    context 'when the entry is tracked' do
      let(:index_status) { 'M' }

      it { is_expected.to be(false) }
    end

    context 'when only the index status is ?' do
      let(:index_status) { '?' }

      it { is_expected.to be(false) }
    end
  end

  describe '#ignored?' do
    subject(:result) { described_instance.ignored? }

    context 'when the entry is ignored (both status characters are !)' do
      let(:index_status) { '!' }
      let(:worktree_status) { '!' }

      it { is_expected.to be(true) }
    end

    context 'when the entry is untracked' do
      let(:index_status) { '?' }
      let(:worktree_status) { '?' }

      it { is_expected.to be(false) }
    end

    context 'when only the index status is !' do
      let(:index_status) { '!' }

      it { is_expected.to be(false) }
    end
  end

  describe '#unmerged?' do
    subject(:result) { described_instance.unmerged? }

    context 'when the entry carries unmerged stage data' do
      let(:index_status) { 'U' }
      let(:worktree_status) { 'U' }
      let(:unmerged_stages) do
        {
          1 => { mode: '100644', sha: sha_head },
          2 => { mode: '100644', sha: sha_index },
          3 => { mode: '100644', sha: sha_index }
        }
      end

      it { is_expected.to be(true) }
    end

    context 'when the entry has no unmerged stage data' do
      it { is_expected.to be(false) }
    end
  end

  describe '#renamed?' do
    subject(:result) { described_instance.renamed? }

    context 'when the index status is R' do
      let(:index_status) { 'R' }
      let(:original_path) { 'lib/old.rb' }
      let(:rename_score) { 100 }

      it { is_expected.to be(true) }
    end

    context 'when the worktree status is R' do
      let(:worktree_status) { 'R' }
      let(:original_path) { 'lib/old.rb' }
      let(:rename_score) { 90 }

      it { is_expected.to be(true) }
    end

    context 'when the entry is a copy (index status C)' do
      let(:index_status) { 'C' }
      let(:original_path) { 'lib/old.rb' }
      let(:rename_score) { 100 }

      it { is_expected.to be(false) }
    end

    context 'when neither status is R' do
      let(:index_status) { 'M' }

      it { is_expected.to be(false) }
    end
  end

  describe '#added?' do
    subject(:result) { described_instance.added? }

    context 'when the index status is A' do
      let(:index_status) { 'A' }

      it { is_expected.to be(true) }
    end

    context 'when only the worktree status is A (intent-to-add)' do
      let(:worktree_status) { 'A' }

      it { is_expected.to be(false) }
    end

    context 'when the index status is not A' do
      let(:index_status) { 'M' }

      it { is_expected.to be(false) }
    end
  end

  describe '#deleted?' do
    subject(:result) { described_instance.deleted? }

    context 'when the index status is D' do
      let(:index_status) { 'D' }

      it { is_expected.to be(true) }
    end

    context 'when the worktree status is D' do
      let(:worktree_status) { 'D' }

      it { is_expected.to be(true) }
    end

    context 'when neither status is D' do
      let(:index_status) { 'M' }

      it { is_expected.to be(false) }
    end
  end

  describe '#changed?' do
    subject(:result) { described_instance.changed? }

    context 'when the index status is M' do
      let(:index_status) { 'M' }

      it { is_expected.to be(true) }
    end

    context 'when the worktree status is M' do
      let(:worktree_status) { 'M' }

      it { is_expected.to be(true) }
    end

    context 'when the index status is T (type change)' do
      let(:index_status) { 'T' }

      it { is_expected.to be(true) }
    end

    context 'when the worktree status is T (type change)' do
      let(:worktree_status) { 'T' }

      it { is_expected.to be(true) }
    end

    context 'when the entry is added but not modified' do
      let(:index_status) { 'A' }

      it { is_expected.to be(false) }
    end

    context 'when the entry is unmodified' do
      it { is_expected.to be(false) }
    end
  end
end
