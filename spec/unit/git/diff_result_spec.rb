# frozen_string_literal: true

require 'spec_helper'
require 'git/diff_result'
require 'git/diff_file_numstat_info'
require 'git/dirstat_info'

RSpec.describe Git::DiffResult do
  let(:files) do
    [
      Git::DiffFileNumstatInfo.new(path: 'lib/foo.rb', src_path: nil, insertions: 5, deletions: 2),
      Git::DiffFileNumstatInfo.new(path: 'lib/bar.rb', src_path: nil, insertions: 3, deletions: 1)
    ]
  end

  describe '.new' do
    it 'creates an immutable result with total stats and files' do
      result = described_class.new(
        files_changed: 2,
        total_insertions: 8,
        total_deletions: 3,
        files: files,
        dirstat: nil
      )

      expect(result.files_changed).to eq(2)
      expect(result.total_insertions).to eq(8)
      expect(result.total_deletions).to eq(3)
      expect(result.files).to eq(files)
      expect(result.dirstat).to be_nil
    end

    it 'is immutable' do
      result = described_class.new(
        files_changed: 2,
        total_insertions: 8,
        total_deletions: 3,
        files: files,
        dirstat: nil
      )

      expect(result).to be_frozen
    end
  end

  describe '#dirstat' do
    it 'returns DirstatInfo when provided' do
      dirstat = Git::DirstatInfo.new(entries: [
                                       Git::DirstatEntry.new(directory: 'lib/', percentage: 100.0)
                                     ])

      result = described_class.new(
        files_changed: 2,
        total_insertions: 8,
        total_deletions: 3,
        files: files,
        dirstat: dirstat
      )

      expect(result.dirstat).to be_a(Git::DirstatInfo)
      expect(result.dirstat['lib/']).to eq(100.0)
    end
  end
end
