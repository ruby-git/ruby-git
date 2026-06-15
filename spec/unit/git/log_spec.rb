# frozen_string_literal: true

require 'spec_helper'
require 'git/log'
require 'git/repository'
require 'git/object'

RSpec.describe Git::Log do
  describe '#initialize' do
    context 'when base is a Git::Repository' do
      subject(:log) { described_class.new(repository, 10) }

      let(:repository) { instance_double(Git::Repository) }

      it 'accepts Git::Repository without raising' do
        expect { log }.not_to raise_error
      end
    end

    context 'when max_count defaults to 30' do
      subject(:log) { described_class.new(repository) }

      let(:repository) { instance_double(Git::Repository) }
      let(:commit_data) { [] }

      before do
        allow(repository).to receive(:full_log_commits).with(hash_including(count: 30)).and_return(commit_data)
      end

      it 'forwards count: 30 to full_log_commits on execute' do
        expect(repository).to receive(:full_log_commits).with(hash_including(count: 30)).and_return(commit_data)
        log.execute
      end
    end
  end

  describe '#execute' do
    let(:commit_data) do
      [{
        'sha' => 'abc123', 'tree' => 'def456', 'parent' => [],
        'author' => 'A', 'committer' => 'B', 'message' => 'msg'
      }]
    end

    context 'when base is a Git::Repository' do
      subject(:result) { log.execute }

      let(:repository) { instance_double(Git::Repository) }
      let(:log) { described_class.new(repository) }

      before do
        allow(repository).to receive(:full_log_commits).and_return(commit_data)
        allow(Git::Object::Commit).to receive(:new).with(repository, 'abc123', commit_data.first)
                                                   .and_return(instance_double(Git::Object::Commit))
      end

      it 'calls full_log_commits directly on the repository' do
        expect(repository).to receive(:full_log_commits).and_return(commit_data)
        result
      end

      it 'returns a Git::Log::Result' do
        expect(result).to be_a(Git::Log::Result)
      end
    end
  end
end
