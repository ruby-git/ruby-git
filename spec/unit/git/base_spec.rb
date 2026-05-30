# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Base do
  shared_context 'with a stubbed facade_repository' do
    let(:described_instance) { described_class.new }
    let(:facade_repository) { instance_double(Git::Repository) }

    before do
      allow(described_instance).to receive(:facade_repository).and_return(facade_repository)
    end
  end

  describe '#binary_path' do
    context 'when not specified' do
      subject(:base) { described_class.new }

      it 'defaults to :use_global_config' do
        expect(base.binary_path).to eq(:use_global_config)
      end
    end

    context 'when an explicit path is provided' do
      subject(:base) { described_class.new(binary_path: '/custom/git') }

      it 'returns the provided path' do
        expect(base.binary_path).to eq('/custom/git')
      end
    end

    context 'when binary_path is explicitly nil' do
      it 'raises ArgumentError' do
        expect { described_class.new(binary_path: nil) }.to raise_error(ArgumentError, /binary_path/)
      end
    end
  end

  describe '#full_log_commits' do
    include_context 'with a stubbed facade_repository'

    subject(:result) { described_instance.full_log_commits(opts) }

    let(:opts) { { count: 3 } }
    let(:log_data) { [{ 'sha' => 'abc123' }] }

    it 'delegates to facade_repository with opts and returns the facade result' do
      expect(facade_repository).to receive(:full_log_commits).with(opts).and_return(log_data)
      expect(result).to eq(log_data)
    end
  end

  describe '#log' do
    include_context 'with a stubbed facade_repository'

    subject(:result) { described_instance.log(count) }

    let(:count) { 5 }
    let(:log_instance) { instance_double(Git::Log) }

    before do
      allow(facade_repository).to receive(:log).with(count).and_return(log_instance)
    end

    it 'delegates to facade_repository.log with count and returns the result' do
      expect(facade_repository).to receive(:log).with(count).and_return(log_instance)
      expect(result).to be(log_instance)
    end

    context 'with default count' do
      subject(:result) { described_instance.log }

      before do
        allow(facade_repository).to receive(:log).with(30).and_return(log_instance)
      end

      it 'passes 30 as the default count' do
        expect(facade_repository).to receive(:log).with(30).and_return(log_instance)
        expect(result).to be(log_instance)
      end
    end
  end

  describe '#diff_stats' do
    include_context 'with a stubbed facade_repository'

    subject(:result) { described_instance.diff_stats(objectish, obj2, opts) }

    let(:objectish) { 'HEAD~1' }
    let(:obj2) { 'HEAD' }
    let(:opts) { { path_limiter: 'lib/' } }
    let(:diff_stats_result) { instance_double(Git::DiffStats) }

    it 'delegates to facade_repository.diff_stats with all arguments' do
      expect(facade_repository).to receive(:diff_stats).with(objectish, obj2, opts).and_return(diff_stats_result)
      expect(result).to be(diff_stats_result)
    end
  end

  describe '#diff' do
    include_context 'with a stubbed facade_repository'

    subject(:result) { described_instance.diff(objectish, obj2) }

    let(:objectish) { 'HEAD~1' }
    let(:obj2) { 'HEAD' }
    let(:diff_result) { instance_double(Git::Diff) }

    it 'delegates to facade_repository.diff with objectish and obj2' do
      expect(facade_repository).to receive(:diff).with(objectish, obj2).and_return(diff_result)
      expect(result).to be(diff_result)
    end

    context 'when called with default arguments' do
      subject(:result) { described_instance.diff }

      before do
        allow(facade_repository).to receive(:diff).with('HEAD', nil).and_return(diff_result)
      end

      it 'delegates to facade_repository.diff with HEAD and nil' do
        expect(facade_repository).to receive(:diff).with('HEAD', nil).and_return(diff_result)
        result
      end
    end
  end

  describe '#worktree' do
    include_context 'with a stubbed facade_repository'

    subject(:result) { described_instance.worktree(dir, commitish) }

    let(:dir) { '/tmp/feature' }
    let(:commitish) { 'main' }
    let(:worktree_double) { instance_double(Git::Worktree) }

    it 'delegates to facade_repository.worktree with dir and commitish' do
      expect(facade_repository).to receive(:worktree).with(dir, commitish).and_return(worktree_double)
      expect(result).to be(worktree_double)
    end

    context 'when called without a commitish' do
      let(:commitish) { nil }

      it 'delegates to facade_repository.worktree with nil as the commitish' do
        expect(facade_repository).to receive(:worktree).with(dir, nil).and_return(worktree_double)
        expect(result).to be(worktree_double)
      end
    end
  end

  describe '#worktrees' do
    include_context 'with a stubbed facade_repository'

    subject(:result) { described_instance.worktrees }

    let(:worktrees_collection) { instance_double(Git::Worktrees) }

    it 'delegates to facade_repository.worktrees' do
      expect(facade_repository).to receive(:worktrees).and_return(worktrees_collection)
      expect(result).to be(worktrees_collection)
    end
  end
end
