# frozen_string_literal: true

require 'spec_helper'
require 'git/diff_path_status'
require 'git/repository'

RSpec.describe Git::DiffPathStatus do
  let(:name_status_hash) { { 'lib/foo.rb' => 'M', 'lib/bar.rb' => 'A' } }

  let(:repository_base)      { instance_double(Git::Repository) }
  let(:diff_name_status_obj) { instance_double(described_class, to_h: name_status_hash) }

  before do
    allow(repository_base).to receive(:diff_name_status).and_return(diff_name_status_obj)
  end

  describe '#initialize' do
    context 'with the hash form' do
      it 'accepts a pre-fetched name-status hash and returns it via to_h' do
        expect(described_class.new(name_status_hash).to_h).to eq(name_status_hash)
      end
    end

    context 'with the legacy form' do
      it 'raises ArgumentError when from starts with a dash' do
        expect { described_class.new(repository_base, '-bad-ref', 'HEAD') }
          .to raise_error(ArgumentError, /Invalid argument/)
      end

      it 'raises ArgumentError when to starts with a dash' do
        expect { described_class.new(repository_base, 'HEAD', '-bad-ref') }
          .to raise_error(ArgumentError, /Invalid argument/)
      end
    end
  end

  describe '#to_h' do
    subject(:result) { described_class.new(repository_base, 'HEAD~1', 'HEAD').to_h }

    it 'calls diff_name_status with from, to, and path_limiter: nil' do
      expect(repository_base).to receive(:diff_name_status)
        .with('HEAD~1', 'HEAD', path_limiter: nil)
        .and_return(diff_name_status_obj)
      result
    end

    it 'returns the name-status hash' do
      expect(result).to eq(name_status_hash)
    end

    context 'when path_limiter is given' do
      it 'forwards path_limiter to diff_name_status' do
        expect(repository_base).to receive(:diff_name_status)
          .with('HEAD~1', 'HEAD', path_limiter: 'lib/')
          .and_return(diff_name_status_obj)
        described_class.new(repository_base, 'HEAD~1', 'HEAD', 'lib/').to_h
      end
    end

    context 'when obj2 is nil' do
      it 'passes nil as the second positional argument to diff_name_status' do
        expect(repository_base).to receive(:diff_name_status)
          .with('HEAD', nil, path_limiter: nil)
          .and_return(diff_name_status_obj)
        described_class.new(repository_base, 'HEAD', nil).to_h
      end
    end

    it 'memoizes the result across multiple to_h calls' do
      expect(repository_base).to receive(:diff_name_status).once.and_return(diff_name_status_obj)
      status = described_class.new(repository_base, 'HEAD', nil)
      status.to_h
      status.to_h
    end
  end

  describe '#each' do
    it 'yields each path and status pair' do
      pairs = described_class.new(repository_base, 'HEAD~1', 'HEAD').map { |path, status| [path, status] }
      expect(pairs).to eq([['lib/foo.rb', 'M'], ['lib/bar.rb', 'A']])
    end

    it 'returns an Enumerator when no block is given' do
      result = described_class.new(repository_base, 'HEAD~1', 'HEAD').each
      expect(result).to be_a(Enumerator)
    end
  end
end
