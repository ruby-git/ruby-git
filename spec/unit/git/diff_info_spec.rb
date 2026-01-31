# frozen_string_literal: true

require 'spec_helper'
require 'git/diff_info'

RSpec.describe Git::FileDiffInfo do
  describe '.new' do
    it 'creates an immutable value object for a modified file' do
      info = described_class.new(
        path: 'lib/example.rb',
        patch: "diff --git a/lib/example.rb b/lib/example.rb\n...",
        mode: '100644',
        src: 'abc1234',
        dst: 'def5678',
        type: 'modified',
        binary: false
      )

      expect(info.path).to eq('lib/example.rb')
      expect(info.patch).to include('diff --git')
      expect(info.mode).to eq('100644')
      expect(info.src).to eq('abc1234')
      expect(info.dst).to eq('def5678')
      expect(info.type).to eq('modified')
      expect(info.binary).to be false
    end

    it 'is immutable' do
      info = described_class.new(
        path: 'file.rb', patch: 'diff', mode: '100644',
        src: 'abc', dst: 'def', type: 'modified', binary: false
      )

      expect(info).to be_frozen
    end
  end

  describe '#binary?' do
    it 'returns true when binary is true' do
      info = described_class.new(
        path: 'image.png', patch: 'Binary files differ', mode: '100644',
        src: 'abc', dst: 'def', type: 'modified', binary: true
      )

      expect(info.binary?).to be true
    end

    it 'returns false when binary is false' do
      info = described_class.new(
        path: 'file.rb', patch: 'diff', mode: '100644',
        src: 'abc', dst: 'def', type: 'modified', binary: false
      )

      expect(info.binary?).to be false
    end
  end
end

RSpec.describe Git::DiffInfo do
  let(:stats) do
    {
      total: { insertions: 10, deletions: 5, lines: 15, files: 2 },
      files: {
        'lib/foo.rb' => { insertions: 8, deletions: 3 },
        'lib/bar.rb' => { insertions: 2, deletions: 2 }
      }
    }
  end

  let(:file_patches) do
    [
      Git::FileDiffInfo.new(
        path: 'lib/foo.rb', patch: 'diff foo', mode: '100644',
        src: 'abc', dst: 'def', type: 'modified', binary: false
      ),
      Git::FileDiffInfo.new(
        path: 'lib/bar.rb', patch: 'diff bar', mode: '100644',
        src: '111', dst: '222', type: 'modified', binary: false
      )
    ]
  end

  let(:diff_info) { described_class.new(stats: stats, file_patches: file_patches) }

  describe '.new' do
    it 'creates an immutable value object with stats and file_patches' do
      expect(diff_info.stats).to eq(stats)
      expect(diff_info.file_patches).to eq(file_patches)
    end

    it 'is immutable' do
      expect(diff_info).to be_frozen
    end
  end

  describe '#insertions' do
    it 'returns total number of lines inserted' do
      expect(diff_info.insertions).to eq(10)
    end
  end

  describe '#deletions' do
    it 'returns total number of lines deleted' do
      expect(diff_info.deletions).to eq(5)
    end
  end

  describe '#lines' do
    it 'returns total number of lines changed' do
      expect(diff_info.lines).to eq(15)
    end
  end

  describe '#file_count' do
    it 'returns number of files changed' do
      expect(diff_info.file_count).to eq(2)
    end
  end

  describe '#file_stats' do
    it 'returns per-file statistics hash' do
      expect(diff_info.file_stats['lib/foo.rb']).to eq(insertions: 8, deletions: 3)
      expect(diff_info.file_stats['lib/bar.rb']).to eq(insertions: 2, deletions: 2)
    end
  end

  describe '#patches?' do
    it 'returns true when file_patches is not empty' do
      expect(diff_info.patches?).to be true
    end

    it 'returns false when file_patches is empty' do
      info = described_class.new(stats: stats, file_patches: [])
      expect(info.patches?).to be false
    end
  end

  describe '#patch_for' do
    it 'returns patch info for a specific file' do
      patch = diff_info.patch_for('lib/foo.rb')

      expect(patch).to be_a(Git::FileDiffInfo)
      expect(patch.path).to eq('lib/foo.rb')
    end

    it 'returns nil when file not found' do
      expect(diff_info.patch_for('nonexistent.rb')).to be_nil
    end
  end
end
