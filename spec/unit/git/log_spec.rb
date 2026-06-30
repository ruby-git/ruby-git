# frozen_string_literal: true

require 'spec_helper'
require 'git/log'
require 'git/repository'
require 'git/object'

RSpec.describe Git::Log do
  let(:repository) { instance_double(Git::Repository) }
  let(:described_instance) { described_class.new(repository) }

  # Commit fixtures used by the deprecated Enumerable interface, which delegates
  # to the commits produced by #execute. #to_s on a real Git::Object::Commit
  # returns its objectish (the sha), so the doubles mirror that.
  let(:commit_data) do
    [{ 'sha' => 'aaa111' }, { 'sha' => 'bbb222' }, { 'sha' => 'ccc333' }]
  end
  let(:commits) do
    commit_data.map do |data|
      instance_double(Git::Object::Commit, sha: data['sha'], to_s: data['sha'])
    end
  end

  describe '#initialize' do
    context 'when base is a Git::Repository' do
      subject(:log) { described_class.new(repository, 10) }

      it 'accepts Git::Repository without raising' do
        expect { log }.not_to raise_error
      end
    end

    context 'when max_count defaults to 30' do
      subject(:log) { described_class.new(repository) }

      it 'forwards count: 30 to full_log_commits on execute' do
        expect(repository).to receive(:full_log_commits).with(hash_including(count: 30)).and_return([])
        log.execute
      end
    end

    context 'when max_count is provided as a constructor argument' do
      subject(:log) { described_class.new(repository, 20) }

      it 'forwards that count to full_log_commits on execute' do
        expect(repository).to receive(:full_log_commits).with(hash_including(count: 20)).and_return([])
        log.execute
      end
    end
  end

  describe '#execute' do
    subject(:result) { described_instance.execute }

    let(:execute_commit_data) do
      [{
        'sha' => 'abc123', 'tree' => 'def456', 'parent' => [],
        'author' => 'A', 'committer' => 'B', 'message' => 'msg'
      }]
    end

    before do
      allow(repository).to receive(:full_log_commits).and_return(execute_commit_data)
      allow(Git::Object::Commit).to receive(:new).with(repository, 'abc123', execute_commit_data.first)
                                                 .and_return(instance_double(Git::Object::Commit))
    end

    it 'calls full_log_commits directly on the repository' do
      expect(repository).to receive(:full_log_commits).and_return(execute_commit_data)
      result
    end

    it 'returns a Git::Log::Result' do
      expect(result).to be_a(Git::Log::Result)
    end

    context 'when called more than once without changing the query' do
      it 'reuses the cached commits without re-querying the repository' do
        expect(repository).to receive(:full_log_commits).once.and_return(execute_commit_data)
        described_instance.execute
        described_instance.execute
      end
    end
  end

  describe '#max_count' do
    before { allow(repository).to receive(:full_log_commits).and_return([]) }

    context 'with an integer' do
      it 'forwards that integer as the count to full_log_commits' do
        expect(repository).to receive(:full_log_commits).with(hash_including(count: 20)).and_return([])
        described_instance.max_count(20).execute
      end
    end

    context 'with nil' do
      it 'forwards a nil count (return all commits) to full_log_commits' do
        expect(repository).to receive(:full_log_commits).with(hash_including(count: nil)).and_return([])
        described_instance.max_count(nil).execute
      end
    end

    context 'with :all' do
      it 'forwards a nil count (return all commits) to full_log_commits' do
        expect(repository).to receive(:full_log_commits).with(hash_including(count: nil)).and_return([])
        described_instance.max_count(:all).execute
      end
    end
  end

  describe '#all' do
    before { allow(repository).to receive(:full_log_commits).and_return([]) }

    it 'adds all refs to the search by forwarding all: true to full_log_commits' do
      expect(repository).to receive(:full_log_commits).with(hash_including(all: true)).and_return([])
      described_instance.all.execute
    end
  end

  # The deprecated Enumerable interface emits a Git::Deprecation warning and
  # delegates to the commits produced by #execute.
  describe 'deprecated Enumerable interface' do
    before do
      allow(repository).to receive(:full_log_commits).and_return(commit_data)
      commit_data.each_with_index do |data, index|
        allow(Git::Object::Commit).to receive(:new).with(repository, data['sha'], data).and_return(commits[index])
      end
      allow(Git::Deprecation).to receive(:warn)
    end

    describe '#each' do
      it 'emits a deprecation warning directing callers to #execute' do
        expect(Git::Deprecation).to receive(:warn).with(
          'Calling Git::Log#each is deprecated. Call #execute and then #each on the result object.'
        )
        described_instance.each { |_commit| nil }
      end

      it 'yields each commit from the executed results' do
        expect { |block| described_instance.each(&block) }.to yield_successive_args(*commits)
      end
    end

    describe '#size' do
      it 'emits a deprecation warning directing callers to #execute' do
        expect(Git::Deprecation).to receive(:warn).with(
          'Calling Git::Log#size is deprecated. Call #execute and then #size on the result object.'
        )
        described_instance.size
      end

      it 'returns the number of commits in the executed results' do
        expect(described_instance.size).to eq(commit_data.size)
      end
    end

    describe '#to_s' do
      it 'emits a deprecation warning directing callers to #execute' do
        expect(Git::Deprecation).to receive(:warn).with(
          'Calling Git::Log#to_s is deprecated. Call #execute and then #to_s on the result object.'
        )
        described_instance.to_s
      end

      it 'returns the executed commits joined by newlines' do
        expect(described_instance.to_s).to eq("aaa111\nbbb222\nccc333")
      end
    end

    describe '#first' do
      it 'emits a deprecation warning directing callers to #execute' do
        expect(Git::Deprecation).to receive(:warn).with(
          'Calling Git::Log#first is deprecated. Call #execute and then #first on the result object.'
        )
        described_instance.first
      end

      it 'returns the first commit from the executed results' do
        expect(described_instance.first).to be(commits.first)
      end
    end

    describe '#last' do
      it 'emits a deprecation warning directing callers to #execute' do
        expect(Git::Deprecation).to receive(:warn).with(
          'Calling Git::Log#last is deprecated. Call #execute and then #last on the result object.'
        )
        described_instance.last
      end

      it 'returns the last commit from the executed results' do
        expect(described_instance.last).to be(commits.last)
      end
    end

    describe '#[]' do
      it 'emits a deprecation warning directing callers to #execute' do
        expect(Git::Deprecation).to receive(:warn).with(
          'Calling Git::Log#[] is deprecated. Call #execute and then #[] on the result object.'
        )
        described_instance[0]
      end

      it 'returns the commit at the given index from the executed results' do
        expect(described_instance[1]).to be(commits[1])
      end
    end
  end
end
