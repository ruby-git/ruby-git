# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::WorktreeInfo do
  # Default attributes describing a linked worktree with a branch checked out
  let(:default_attrs) do
    {
      path: '/tmp/wt/linked',
      head: 'f3e2c1ffb860086504eeb27b77a1d0028b68fd8f',
      branch: 'refs/heads/linked',
      bare: false,
      detached: false,
      locked: false,
      lock_reason: nil,
      prunable: false,
      prune_reason: nil
    }
  end

  describe '#initialize' do
    subject(:info) { described_class.new(**default_attrs) }

    it 'stores all members' do
      expect(info).to have_attributes(**default_attrs)
    end

    context 'with a bare main worktree' do
      subject(:info) do
        described_class.new(**default_attrs, path: '/tmp/repo.git', head: nil, branch: nil, bare: true)
      end

      it 'has a nil head and branch' do
        expect(info).to have_attributes(path: '/tmp/repo.git', head: nil, branch: nil, bare: true)
      end
    end

    context 'with a detached worktree' do
      subject(:info) { described_class.new(**default_attrs, branch: nil, detached: true) }

      it 'has a nil branch' do
        expect(info).to have_attributes(branch: nil, detached: true)
      end
    end
  end

  describe '#bare?' do
    it 'returns true when bare is true' do
      info = described_class.new(**default_attrs, head: nil, branch: nil, bare: true)
      expect(info.bare?).to be true
    end

    it 'returns false when bare is false' do
      info = described_class.new(**default_attrs)
      expect(info.bare?).to be false
    end
  end

  describe '#detached?' do
    it 'returns true when detached is true' do
      info = described_class.new(**default_attrs, branch: nil, detached: true)
      expect(info.detached?).to be true
    end

    it 'returns false when detached is false' do
      info = described_class.new(**default_attrs)
      expect(info.detached?).to be false
    end
  end

  describe '#locked?' do
    it 'returns true when locked is true' do
      info = described_class.new(**default_attrs, locked: true, lock_reason: 'on purpose')
      expect(info.locked?).to be true
    end

    it 'returns true when locked without a reason' do
      info = described_class.new(**default_attrs, locked: true, lock_reason: nil)
      expect(info.locked?).to be true
    end

    it 'returns false when locked is false' do
      info = described_class.new(**default_attrs)
      expect(info.locked?).to be false
    end
  end

  describe '#prunable?' do
    it 'returns true when prunable is true' do
      info = described_class.new(
        **default_attrs, prunable: true, prune_reason: 'gitdir file points to non-existent location'
      )
      expect(info.prunable?).to be true
    end

    it 'returns false when prunable is false' do
      info = described_class.new(**default_attrs)
      expect(info.prunable?).to be false
    end
  end

  describe '#to_s' do
    it 'returns the worktree path' do
      info = described_class.new(**default_attrs)
      expect(info.to_s).to eq('/tmp/wt/linked')
    end
  end

  describe 'immutability' do
    it 'is frozen' do
      info = described_class.new(**default_attrs)
      expect(info).to be_frozen
    end
  end

  describe 'equality' do
    it 'considers two infos with the same attributes equal' do
      expect(described_class.new(**default_attrs)).to eq(described_class.new(**default_attrs))
    end

    it 'considers two infos with different attributes not equal' do
      info1 = described_class.new(**default_attrs)
      info2 = described_class.new(**default_attrs, path: '/tmp/wt/other')
      expect(info1).not_to eq(info2)
    end
  end
end
