# frozen_string_literal: true

require 'spec_helper'
require 'git/status_info'

RSpec.describe Git::StatusInfo do
  # Build a Git::StatusFileInfo with the given status characters and defaults for
  # every other member. Value objects with no IO are used directly rather than
  # doubled.
  def file_info(path, index_status: '.', worktree_status: '.', unmerged_stages: nil)
    Git::StatusFileInfo.new(
      path: path, index_status: index_status, worktree_status: worktree_status, submodule: 'N...',
      mode_head: '100644', mode_index: '100644', mode_worktree: '100644',
      sha_head: '1111111111111111111111111111111111111111',
      sha_index: '2222222222222222222222222222222222222222',
      original_path: nil, rename_score: nil, unmerged_stages: unmerged_stages
    )
  end

  let(:staged_modified) { file_info('lib/staged.rb', index_status: 'M') }
  let(:worktree_modified) { file_info('lib/worktree.rb', worktree_status: 'M') }
  let(:type_changed) { file_info('lib/typed.rb', worktree_status: 'T') }
  let(:added) { file_info('lib/added.rb', index_status: 'A') }
  let(:deleted) { file_info('lib/deleted.rb', index_status: 'D') }
  let(:untracked) { file_info('lib/untracked.rb', index_status: '?', worktree_status: '?') }
  let(:unmerged) do
    stages = { 1 => { mode: '100644', sha: 'a' * 40 }, 2 => { mode: '100644', sha: 'b' * 40 },
               3 => { mode: '100644', sha: 'c' * 40 } }
    file_info('lib/conflict.rb', index_status: 'U', worktree_status: 'U', unmerged_stages: stages)
  end
  let(:files) { [staged_modified, worktree_modified, type_changed, added, deleted, untracked, unmerged] }
  let(:ignore_case) { false }
  let(:described_instance) { described_class.new(files: files, ignore_case: ignore_case) }

  describe '#initialize' do
    subject(:instance) { described_instance }

    it 'stores the files and the ignore_case flag' do
      expect(instance).to have_attributes(files: files, ignore_case: false)
    end

    it 'creates an immutable object whose files array is frozen' do
      expect(instance).to be_frozen
      expect(instance.files).to be_frozen
      expect { instance.files = [] }.to raise_error(NoMethodError, /files=/)
    end

    it 'does not freeze the array the caller passed in' do
      instance
      expect(files).not_to be_frozen
    end

    it 'compares equal to another instance with the same values' do
      expect(instance).to eq(described_class.new(files: files.dup, ignore_case: false))
    end

    it 'does not compare equal to an instance with different values' do
      expect(instance).not_to eq(described_class.new(files: files, ignore_case: true))
    end
  end

  describe '#changed' do
    subject(:result) { described_instance.changed }

    it 'returns the files modified or type-changed in the index or worktree, keyed by path' do
      expect(result).to eq(
        'lib/staged.rb' => staged_modified,
        'lib/worktree.rb' => worktree_modified,
        'lib/typed.rb' => type_changed
      )
    end

    it 'preserves the order git listed the files in' do
      expect(result.keys).to eq(['lib/staged.rb', 'lib/worktree.rb', 'lib/typed.rb'])
    end

    context 'when no file is changed' do
      let(:files) { [added, untracked] }

      it 'returns an empty hash' do
        expect(result).to eq({})
      end
    end
  end

  describe '#added' do
    subject(:result) { described_instance.added }

    it 'returns the files added to the index, keyed by path' do
      expect(result).to eq('lib/added.rb' => added)
    end
  end

  describe '#deleted' do
    subject(:result) { described_instance.deleted }

    it 'returns the deleted files, keyed by path' do
      expect(result).to eq('lib/deleted.rb' => deleted)
    end
  end

  describe '#untracked' do
    subject(:result) { described_instance.untracked }

    it 'returns the untracked files, keyed by path' do
      expect(result).to eq('lib/untracked.rb' => untracked)
    end
  end

  describe '#unmerged' do
    subject(:result) { described_instance.unmerged }

    it 'returns the unmerged files, keyed by path' do
      expect(result).to eq('lib/conflict.rb' => unmerged)
    end
  end

  describe '#changed?' do
    context 'when ignore_case is false' do
      it 'returns true for the exact path of a changed file' do
        expect(described_instance.changed?('lib/staged.rb')).to be(true)
      end

      it 'returns false for a different-cased path' do
        expect(described_instance.changed?('LIB/STAGED.RB')).to be(false)
      end

      it 'returns false for a file that is not changed' do
        expect(described_instance.changed?('lib/added.rb')).to be(false)
      end
    end

    context 'when ignore_case is true' do
      let(:ignore_case) { true }

      it 'returns true for a different-cased path of a changed file' do
        expect(described_instance.changed?('LIB/STAGED.RB')).to be(true)
      end

      it 'returns false for a path that matches no changed file in any case' do
        expect(described_instance.changed?('lib/missing.rb')).to be(false)
      end
    end
  end

  describe '#added?' do
    context 'when ignore_case is false' do
      it 'returns true for the exact path of an added file' do
        expect(described_instance.added?('lib/added.rb')).to be(true)
      end

      it 'returns false for a different-cased path' do
        expect(described_instance.added?('LIB/ADDED.RB')).to be(false)
      end
    end

    context 'when ignore_case is true' do
      let(:ignore_case) { true }

      it 'returns true for a different-cased path of an added file' do
        expect(described_instance.added?('LIB/ADDED.RB')).to be(true)
      end
    end
  end

  describe '#deleted?' do
    context 'when ignore_case is false' do
      it 'returns true for the exact path of a deleted file' do
        expect(described_instance.deleted?('lib/deleted.rb')).to be(true)
      end

      it 'returns false for a different-cased path' do
        expect(described_instance.deleted?('LIB/DELETED.RB')).to be(false)
      end
    end

    context 'when ignore_case is true' do
      let(:ignore_case) { true }

      it 'returns true for a different-cased path of a deleted file' do
        expect(described_instance.deleted?('LIB/DELETED.RB')).to be(true)
      end
    end
  end

  describe '#untracked?' do
    context 'when ignore_case is false' do
      it 'returns true for the exact path of an untracked file' do
        expect(described_instance.untracked?('lib/untracked.rb')).to be(true)
      end

      it 'returns false for a different-cased path' do
        expect(described_instance.untracked?('LIB/UNTRACKED.RB')).to be(false)
      end
    end

    context 'when ignore_case is true' do
      let(:ignore_case) { true }

      it 'returns true for a different-cased path of an untracked file' do
        expect(described_instance.untracked?('LIB/UNTRACKED.RB')).to be(true)
      end
    end
  end

  describe '#[]' do
    it 'returns the file with the given path' do
      expect(described_instance['lib/deleted.rb']).to eq(deleted)
    end

    it 'returns nil when no file has the given path' do
      expect(described_instance['lib/missing.rb']).to be_nil
    end

    it 'matches the path exactly even when ignore_case is true' do
      instance = described_class.new(files: files, ignore_case: true)
      expect(instance['LIB/DELETED.RB']).to be_nil
    end
  end
end
