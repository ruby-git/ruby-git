# frozen_string_literal: true

require 'spec_helper'
require 'git/diff_file_raw_info'

RSpec.describe Git::DiffFileRawInfo do
  describe '.new' do
    it 'creates an immutable value object for a modified file' do
      info = described_class.new(
        src: Git::FileRef.new(mode: '100644', sha: 'abc1234', path: 'lib/foo.rb'),
        dst: Git::FileRef.new(mode: '100644', sha: 'def5678', path: 'lib/foo.rb'),
        status: :modified,
        similarity: nil,
        insertions: 5,
        deletions: 2,
        binary: false
      )

      expect(info.path).to eq('lib/foo.rb')
      expect(info.status).to eq(:modified)
      expect(info.insertions).to eq(5)
      expect(info.deletions).to eq(2)
      expect(info.src).to be_a(Git::FileRef)
      expect(info.dst).to be_a(Git::FileRef)
      expect(info.similarity).to be_nil
      expect(info.binary?).to be false
    end

    it 'creates an immutable value object for a renamed file' do
      info = described_class.new(
        src: Git::FileRef.new(mode: '100644', sha: 'abc1234', path: 'lib/old_name.rb'),
        dst: Git::FileRef.new(mode: '100644', sha: 'def5678', path: 'lib/new_name.rb'),
        status: :renamed,
        similarity: 95,
        insertions: 3,
        deletions: 1,
        binary: false
      )

      expect(info.path).to eq('lib/new_name.rb')
      expect(info.status).to eq(:renamed)
      expect(info.insertions).to eq(3)
      expect(info.deletions).to eq(1)
      expect(info.src_path).to eq('lib/old_name.rb')
      expect(info.similarity).to eq(95)
    end

    it 'creates an immutable value object for an added file' do
      info = described_class.new(
        src: nil,
        dst: Git::FileRef.new(mode: '100644', sha: 'abc1234', path: 'lib/new.rb'),
        status: :added,
        similarity: nil,
        insertions: 10,
        deletions: 0,
        binary: false
      )

      expect(info.path).to eq('lib/new.rb')
      expect(info.status).to eq(:added)
      expect(info.src).to be_nil
      expect(info.dst).to be_a(Git::FileRef)
    end

    it 'creates an immutable value object for a deleted file' do
      info = described_class.new(
        src: Git::FileRef.new(mode: '100644', sha: 'abc1234', path: 'lib/removed.rb'),
        dst: nil,
        status: :deleted,
        similarity: nil,
        insertions: 0,
        deletions: 20,
        binary: false
      )

      expect(info.path).to eq('lib/removed.rb')
      expect(info.status).to eq(:deleted)
      expect(info.src).to be_a(Git::FileRef)
      expect(info.dst).to be_nil
    end

    it 'is immutable' do
      info = described_class.new(
        src: nil,
        dst: Git::FileRef.new(mode: '100644', sha: 'abc1234', path: 'lib/foo.rb'),
        status: :added,
        similarity: nil,
        insertions: 10,
        deletions: 0,
        binary: false
      )

      expect(info).to be_frozen
    end
  end

  describe '#path' do
    it 'returns dst.path when dst is present' do
      info = described_class.new(
        src: Git::FileRef.new(mode: '100644', sha: 'abc1234', path: 'old.rb'),
        dst: Git::FileRef.new(mode: '100644', sha: 'def5678', path: 'new.rb'),
        status: :renamed,
        similarity: 95,
        insertions: 0,
        deletions: 0,
        binary: false
      )

      expect(info.path).to eq('new.rb')
    end

    it 'returns src.path when dst is nil' do
      info = described_class.new(
        src: Git::FileRef.new(mode: '100644', sha: 'abc1234', path: 'deleted.rb'),
        dst: nil,
        status: :deleted,
        similarity: nil,
        insertions: 0,
        deletions: 5,
        binary: false
      )

      expect(info.path).to eq('deleted.rb')
    end
  end

  describe '#src_path' do
    it 'returns src.path when src is present' do
      info = described_class.new(
        src: Git::FileRef.new(mode: '100644', sha: 'abc1234', path: 'lib/foo.rb'),
        dst: Git::FileRef.new(mode: '100644', sha: 'def5678', path: 'lib/foo.rb'),
        status: :modified,
        similarity: nil,
        insertions: 5,
        deletions: 2,
        binary: false
      )

      expect(info.src_path).to eq('lib/foo.rb')
    end

    it 'returns nil when src is nil' do
      info = described_class.new(
        src: nil,
        dst: Git::FileRef.new(mode: '100644', sha: 'abc1234', path: 'new.rb'),
        status: :added,
        similarity: nil,
        insertions: 10,
        deletions: 0,
        binary: false
      )

      expect(info.src_path).to be_nil
    end
  end

  describe '#binary?' do
    it 'returns true for binary files' do
      info = described_class.new(
        src: Git::FileRef.new(mode: '100644', sha: 'abc1234', path: 'image.png'),
        dst: Git::FileRef.new(mode: '100644', sha: 'def5678', path: 'image.png'),
        status: :modified,
        similarity: nil,
        insertions: 0,
        deletions: 0,
        binary: true
      )
      expect(info.binary?).to be true
    end

    it 'returns false for text files' do
      info = described_class.new(
        src: Git::FileRef.new(mode: '100644', sha: 'abc1234', path: 'file.rb'),
        dst: Git::FileRef.new(mode: '100644', sha: 'def5678', path: 'file.rb'),
        status: :modified,
        similarity: nil,
        insertions: 5,
        deletions: 2,
        binary: false
      )
      expect(info.binary?).to be false
    end
  end

  describe '#renamed?' do
    it 'returns true for renamed files' do
      info = described_class.new(
        src: Git::FileRef.new(mode: '100644', sha: 'abc1234', path: 'old.rb'),
        dst: Git::FileRef.new(mode: '100644', sha: 'def5678', path: 'new.rb'),
        status: :renamed,
        similarity: 90,
        insertions: 2,
        deletions: 1,
        binary: false
      )
      expect(info.renamed?).to be true
    end

    it 'returns false for modified files' do
      info = described_class.new(
        src: Git::FileRef.new(mode: '100644', sha: 'abc1234', path: 'file.rb'),
        dst: Git::FileRef.new(mode: '100644', sha: 'def5678', path: 'file.rb'),
        status: :modified,
        similarity: nil,
        insertions: 5,
        deletions: 2,
        binary: false
      )
      expect(info.renamed?).to be false
    end
  end

  describe '#copied?' do
    it 'returns true for copied files' do
      info = described_class.new(
        src: Git::FileRef.new(mode: '100644', sha: 'abc1234', path: 'original.rb'),
        dst: Git::FileRef.new(mode: '100644', sha: 'abc1234', path: 'copy.rb'),
        status: :copied,
        similarity: 100,
        insertions: 0,
        deletions: 0,
        binary: false
      )
      expect(info.copied?).to be true
    end

    it 'returns false for added files' do
      info = described_class.new(
        src: nil,
        dst: Git::FileRef.new(mode: '100644', sha: 'abc1234', path: 'file.rb'),
        status: :added,
        similarity: nil,
        insertions: 10,
        deletions: 0,
        binary: false
      )
      expect(info.copied?).to be false
    end
  end

  describe '#added?' do
    it 'returns true for added files' do
      info = described_class.new(
        src: nil,
        dst: Git::FileRef.new(mode: '100644', sha: 'abc1234', path: 'new.rb'),
        status: :added,
        similarity: nil,
        insertions: 10,
        deletions: 0,
        binary: false
      )
      expect(info.added?).to be true
    end
  end

  describe '#deleted?' do
    it 'returns true for deleted files' do
      info = described_class.new(
        src: Git::FileRef.new(mode: '100644', sha: 'abc1234', path: 'removed.rb'),
        dst: nil,
        status: :deleted,
        similarity: nil,
        insertions: 0,
        deletions: 10,
        binary: false
      )
      expect(info.deleted?).to be true
    end
  end
end
