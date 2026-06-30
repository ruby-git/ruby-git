# frozen_string_literal: true

require 'spec_helper'
require 'git/diff_stats'
require 'git/repository'

RSpec.describe Git::DiffStats do
  let(:stats_hash) do
    {
      total: { insertions: 5, deletions: 3, lines: 8, files: 2 },
      files: { 'lib/foo.rb' => { insertions: 3, deletions: 2 } }
    }
  end

  let(:repository_base) { instance_double(Git::Repository) }

  before do
    allow(repository_base).to receive(:diff_numstat).and_return(stats_hash)
  end

  describe '#initialize' do
    it 'raises ArgumentError when from starts with a dash' do
      expect { described_class.new(repository_base, '-bad-ref', 'HEAD') }
        .to raise_error(ArgumentError, /Invalid argument/)
    end

    it 'raises ArgumentError when to starts with a dash' do
      expect { described_class.new(repository_base, 'HEAD', '-bad-ref') }
        .to raise_error(ArgumentError, /Invalid argument/)
    end
  end

  describe '#insertions' do
    subject(:result) { described_class.new(repository_base, 'HEAD~1', 'HEAD').insertions }

    it 'calls diff_numstat with from, to, and path_limiter: nil' do
      expect(repository_base).to receive(:diff_numstat)
        .with('HEAD~1', 'HEAD', path_limiter: nil)
        .and_return(stats_hash)
      result
    end

    it 'returns the total insertions from the diff_numstat result' do
      expect(result).to eq(5)
    end

    context 'when path_limiter is given' do
      it 'forwards path_limiter to diff_numstat' do
        expect(repository_base).to receive(:diff_numstat)
          .with('HEAD~1', 'HEAD', path_limiter: 'lib/')
          .and_return(stats_hash)
        described_class.new(repository_base, 'HEAD~1', 'HEAD', 'lib/').insertions
      end
    end

    context 'when path_limiter is an empty Array' do
      it 'forwards path_limiter: [] to diff_numstat (normalization is the diffing layer\'s responsibility)' do
        expect(repository_base).to receive(:diff_numstat)
          .with('HEAD~1', 'HEAD', path_limiter: [])
          .and_return(stats_hash)
        described_class.new(repository_base, 'HEAD~1', 'HEAD', []).insertions
      end
    end

    context 'when obj2 is nil' do
      it 'passes nil as the second positional argument to diff_numstat' do
        expect(repository_base).to receive(:diff_numstat)
          .with('HEAD', nil, path_limiter: nil)
          .and_return(stats_hash)
        described_class.new(repository_base, 'HEAD', nil).insertions
      end
    end

    it 'memoizes the diff_numstat result across multiple accessor calls' do
      expect(repository_base).to receive(:diff_numstat).once.and_return(stats_hash)
      stats = described_class.new(repository_base, 'HEAD', nil)
      stats.insertions
      stats.deletions
    end
  end

  describe '#deletions' do
    it 'returns the total deletions from the stats hash' do
      expect(described_class.new(repository_base, 'HEAD~1', 'HEAD').deletions).to eq(3)
    end
  end

  describe '#lines' do
    it 'returns the total lines from the stats hash' do
      expect(described_class.new(repository_base, 'HEAD~1', 'HEAD').lines).to eq(8)
    end
  end

  describe '#total' do
    it 'returns the total sub-hash from the stats' do
      expect(described_class.new(repository_base, 'HEAD~1', 'HEAD').total)
        .to eq(insertions: 5, deletions: 3, lines: 8, files: 2)
    end
  end

  describe '#files' do
    it 'returns the per-file stats hash' do
      expect(described_class.new(repository_base, 'HEAD~1', 'HEAD').files)
        .to eq('lib/foo.rb' => { insertions: 3, deletions: 2 })
    end
  end
end
