# frozen_string_literal: true

require 'spec_helper'
require 'git/diff_file_patch_info'

RSpec.describe Git::DiffFilePatchInfo do
  describe '#path' do
    it 'returns dst.path when dst is present' do
      patch = described_class.new(
        src: Git::FileRef.new(mode: '100644', sha: 'abc1234', path: 'old.rb'),
        dst: Git::FileRef.new(mode: '100644', sha: 'def5678', path: 'new.rb'),
        patch: 'diff text',
        status: :renamed,
        similarity: 95,
        binary: false,
        insertions: 0,
        deletions: 0
      )

      expect(patch.path).to eq('new.rb')
    end

    it 'returns src.path when dst is nil' do
      patch = described_class.new(
        src: Git::FileRef.new(mode: '100644', sha: 'abc1234', path: 'deleted.rb'),
        dst: nil,
        patch: 'diff text',
        status: :deleted,
        similarity: nil,
        binary: false,
        insertions: 0,
        deletions: 5
      )

      expect(patch.path).to eq('deleted.rb')
    end
  end

  describe '#src_path' do
    it 'returns src.path when src is present' do
      patch = described_class.new(
        src: Git::FileRef.new(mode: '100644', sha: 'abc1234', path: 'old_name.rb'),
        dst: Git::FileRef.new(mode: '100644', sha: 'def5678', path: 'new_name.rb'),
        patch: 'diff text',
        status: :renamed,
        similarity: 95,
        binary: false,
        insertions: 0,
        deletions: 0
      )

      expect(patch.src_path).to eq('old_name.rb')
    end

    it 'returns nil when src is nil' do
      patch = described_class.new(
        src: nil,
        dst: Git::FileRef.new(mode: '100644', sha: 'abc1234', path: 'new.rb'),
        patch: 'diff text',
        status: :added,
        similarity: nil,
        binary: false,
        insertions: 10,
        deletions: 0
      )

      expect(patch.src_path).to be_nil
    end
  end

  describe '#binary?' do
    it 'returns true when binary is true' do
      patch = described_class.new(
        src: Git::FileRef.new(mode: '100644', sha: 'abc1234', path: 'image.png'),
        dst: Git::FileRef.new(mode: '100644', sha: 'def5678', path: 'image.png'),
        patch: 'Binary files differ',
        status: :modified,
        similarity: nil,
        binary: true,
        insertions: 0,
        deletions: 0
      )

      expect(patch.binary?).to be true
    end

    it 'returns false when binary is false' do
      patch = described_class.new(
        src: Git::FileRef.new(mode: '100644', sha: 'abc1234', path: 'file.rb'),
        dst: Git::FileRef.new(mode: '100644', sha: 'def5678', path: 'file.rb'),
        patch: 'diff text',
        status: :modified,
        similarity: nil,
        binary: false,
        insertions: 5,
        deletions: 2
      )

      expect(patch.binary?).to be false
    end
  end

  describe '#added?' do
    it 'returns true for added status' do
      patch = described_class.new(
        src: nil,
        dst: Git::FileRef.new(mode: '100644', sha: 'abc1234', path: 'new.rb'),
        patch: 'diff text',
        status: :added,
        similarity: nil,
        binary: false,
        insertions: 5,
        deletions: 0
      )

      expect(patch.added?).to be true
    end
  end

  describe '#deleted?' do
    it 'returns true for deleted status' do
      patch = described_class.new(
        src: Git::FileRef.new(mode: '100644', sha: 'abc1234', path: 'removed.rb'),
        dst: nil,
        patch: 'diff text',
        status: :deleted,
        similarity: nil,
        binary: false,
        insertions: 0,
        deletions: 10
      )

      expect(patch.deleted?).to be true
    end
  end

  describe '#renamed?' do
    it 'returns true for renamed status' do
      patch = described_class.new(
        src: Git::FileRef.new(mode: '100644', sha: 'abc1234', path: 'old_name.rb'),
        dst: Git::FileRef.new(mode: '100644', sha: 'def5678', path: 'new_name.rb'),
        patch: 'diff text',
        status: :renamed,
        similarity: 95,
        binary: false,
        insertions: 0,
        deletions: 0
      )

      expect(patch.renamed?).to be true
      expect(patch.similarity).to eq(95)
    end
  end

  describe '#copied?' do
    it 'returns true for copied status' do
      patch = described_class.new(
        src: Git::FileRef.new(mode: '100644', sha: 'abc1234', path: 'original.rb'),
        dst: Git::FileRef.new(mode: '100644', sha: 'abc1234', path: 'copy.rb'),
        patch: 'diff text',
        status: :copied,
        similarity: 100,
        binary: false,
        insertions: 0,
        deletions: 0
      )

      expect(patch.copied?).to be true
    end
  end
end
