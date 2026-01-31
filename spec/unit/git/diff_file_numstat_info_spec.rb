# frozen_string_literal: true

require 'spec_helper'
require 'git/diff_result'
require 'git/diff_file_numstat_info'
require 'git/dirstat_info'

RSpec.describe Git::DiffFileNumstatInfo do
  describe '.new' do
    it 'creates an immutable value object with path, src_path, insertions, deletions' do
      info = described_class.new(path: 'lib/foo.rb', src_path: nil, insertions: 5, deletions: 2)

      expect(info.path).to eq('lib/foo.rb')
      expect(info.src_path).to be_nil
      expect(info.insertions).to eq(5)
      expect(info.deletions).to eq(2)
    end

    it 'is immutable' do
      info = described_class.new(path: 'lib/foo.rb', src_path: nil, insertions: 5, deletions: 2)

      expect(info).to be_frozen
    end
  end

  describe '#renamed?' do
    it 'returns true when src_path is present' do
      info = described_class.new(path: 'new.rb', src_path: 'old.rb', insertions: 3, deletions: 1)

      expect(info.renamed?).to be true
    end

    it 'returns false when src_path is nil' do
      info = described_class.new(path: 'file.rb', src_path: nil, insertions: 5, deletions: 2)

      expect(info.renamed?).to be false
    end
  end
end
