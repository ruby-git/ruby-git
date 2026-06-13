# frozen_string_literal: true

require 'spec_helper'
require 'git/remote'

RSpec.describe Git::Remote do
  # Git::Remote accepts either Git::Repository (new form) or Git::Base (legacy) as base.
  # These specs cover both the Git::Repository path and the Git::Base duck-type path
  # for the remote_repository bridge method.

  let(:execution_context) { instance_double(Git::ExecutionContext::Repository) }
  let(:base) { Git::Repository.new(execution_context: execution_context) }
  let(:remote_config) do
    { 'url' => 'https://github.com/test/repo.git', 'fetch' => '+refs/heads/*:refs/remotes/origin/*' }
  end

  before do
    allow(base).to receive(:config_remote).with('origin').and_return(remote_config)
  end

  let(:described_instance) { described_class.new(base, 'origin') }

  # ---------------------------------------------------------------------------
  # #initialize
  # ---------------------------------------------------------------------------

  describe '#initialize' do
    context 'when base is a Git::Repository' do
      subject(:remote) { described_instance }

      it 'sets the name' do
        expect(remote.name).to eq('origin')
      end

      it 'sets the url from config' do
        expect(remote.url).to eq('https://github.com/test/repo.git')
      end

      it 'sets fetch_opts from config' do
        expect(remote.fetch_opts).to eq('+refs/heads/*:refs/remotes/origin/*')
      end

      it 'calls config_remote on the repository' do
        expect(base).to receive(:config_remote).with('origin').and_return(remote_config)
        remote
      end
    end

    context 'when base is a Git::Base instance' do
      subject(:remote) { described_class.new(base_like, 'origin') }

      let(:facade_repo) { instance_double(Git::Repository) }
      # Plain object with is_a?(Git::Base) returning true — simulates the legacy
      # Git::Base path without requiring a real Git repository on disk.
      let(:base_like) do
        repo = facade_repo
        Object.new.tap do |obj|
          obj.define_singleton_method(:facade_repository) { repo }
          obj.define_singleton_method(:is_a?) { |klass| klass == Git::Base || super(klass) }
        end
      end

      before do
        allow(facade_repo).to receive(:config_remote).with('origin').and_return(remote_config)
      end

      it 'delegates config_remote through facade_repository' do
        expect(facade_repo).to receive(:config_remote).with('origin').and_return(remote_config)
        remote
      end

      it 'sets the name' do
        expect(remote.name).to eq('origin')
      end

      it 'sets the url from config' do
        expect(remote.url).to eq('https://github.com/test/repo.git')
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #remove
  # ---------------------------------------------------------------------------

  describe '#remove' do
    subject(:result) { described_instance.remove }

    let(:remove_result) { command_result('') }

    it 'delegates to remote_repository.remote_remove with the remote name' do
      expect(base).to receive(:remote_remove).with('origin').and_return(remove_result)
      result
    end

    it 'returns the result of remote_remove' do
      allow(base).to receive(:remote_remove).with('origin').and_return(remove_result)
      expect(result).to be(remove_result)
    end
  end

  # ---------------------------------------------------------------------------
  # #fetch
  # ---------------------------------------------------------------------------

  describe '#fetch' do
    subject(:result) { described_instance.fetch }

    it 'delegates to base.fetch with the remote name' do
      expect(base).to receive(:fetch).with('origin', {}).and_return('')
      result
    end

    it 'forwards options to base.fetch' do
      expect(base).to receive(:fetch).with('origin', { depth: 1 }).and_return('')
      described_instance.fetch(depth: 1)
    end
  end

  # ---------------------------------------------------------------------------
  # #merge
  # ---------------------------------------------------------------------------

  describe '#merge' do
    context 'when branch is specified explicitly' do
      it 'merges the remote-tracking branch into the given branch' do
        expect(base).to receive(:merge).with('origin/main').and_return('')
        described_instance.merge('main')
      end
    end

    context 'when branch defaults to current_branch' do
      before { allow(base).to receive(:current_branch).and_return('develop') }

      it 'merges the remote-tracking branch for the current branch' do
        expect(base).to receive(:merge).with('origin/develop').and_return('')
        described_instance.merge
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #branch
  # ---------------------------------------------------------------------------

  describe '#branch' do
    context 'when branch is specified explicitly' do
      it 'returns a Git::Branch for <remote>/<branch>' do
        result = described_instance.branch('main')
        expect(result).to be_a(Git::Branch)
        expect(result.full).to eq('origin/main')
      end
    end

    context 'when branch defaults to current_branch' do
      before { allow(base).to receive(:current_branch).and_return('develop') }

      it 'returns a Git::Branch for <remote>/<current_branch>' do
        result = described_instance.branch
        expect(result).to be_a(Git::Branch)
        expect(result.full).to eq('origin/develop')
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #to_s
  # ---------------------------------------------------------------------------

  describe '#to_s' do
    subject(:result) { described_instance.to_s }

    it 'returns the remote name' do
      expect(result).to eq('origin')
    end
  end
end
