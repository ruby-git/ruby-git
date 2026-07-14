# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/remote_operations'

RSpec.describe Git::Repository::RemoteOperations, :integration do
  include_context 'in an empty repository'

  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  let(:bare_dir) { Dir.mktmpdir('bare_repo') }

  after do
    FileUtils.rm_rf(bare_dir)
  end

  before do
    write_file('README.md', "# Hello\n")
    repo.add('README.md')
    repo.commit('Initial commit')

    Git.init(bare_dir, bare: true, initial_branch: 'main')
    repo.remote_add('origin', bare_dir)
    repo.push('origin', 'main')
  end

  # ---------------------------------------------------------------------------
  # #fetch — basic invocations
  # ---------------------------------------------------------------------------

  describe '#fetch' do
    context 'when opts is passed as the first argument (Hash-only form)' do
      it 'returns a String when fetching without an explicit remote' do
        result = described_instance.fetch(prune: true)
        expect(result).to be_a(String)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #push — basic invocations
  # ---------------------------------------------------------------------------

  describe '#push' do
    context 'with tags: true' do
      before do
        repo.tag_add('v1.0')
      end
    end

    context 'with no remote or branch arguments (tracking branch workflow)' do
      let(:clone_parent_dir) { Dir.mktmpdir('clone_parent') }
      let(:bare_origin_dir) { File.join(clone_parent_dir, 'origin.git') }
      let(:clone_dir) { File.join(clone_parent_dir, 'clone') }

      after { FileUtils.rm_rf(clone_parent_dir) }

      context 'when the clone has a new commit to push' do
        let(:clone_instance) do
          Git.init(bare_origin_dir, bare: true)
          git = Git.clone(bare_origin_dir, clone_dir)
          git.config_set('user.email', 'test@example.com')
          git.config_set('user.name', 'Test User')
          git.config_set('commit.gpgsign', 'false')
          File.write(File.join(clone_dir, 'file.txt'), 'content')
          git.add('file.txt')
          git.commit('First commit')
          Git::Repository.new(execution_context: git.execution_context)
        end
      end

      context 'when the clone has no commits to push' do
        let(:clone_instance) do
          Git.init(bare_origin_dir, bare: true)
          git = Git.clone(bare_origin_dir, clone_dir)
          git.config_set('user.email', 'test@example.com')
          git.config_set('user.name', 'Test User')
          git.config_set('commit.gpgsign', 'false')
          Git::Repository.new(execution_context: git.execution_context)
        end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #pull — basic invocations
  # ---------------------------------------------------------------------------

  # ---------------------------------------------------------------------------
  # #remote_add — basic invocations
  # ---------------------------------------------------------------------------

  describe '#remote_add' do
    let(:remote_dir) { Dir.mktmpdir('remote_repo') }

    after do
      FileUtils.rm_rf(remote_dir)
    end

    before do
      Git.init(remote_dir, bare: true)
    end

    it 'registers the remote so it appears in the repository config' do
      described_instance.remote_add('secondary', remote_dir)
      expect(repo.remotes.map(&:name)).to include('secondary')
    end
  end

  # ---------------------------------------------------------------------------
  # #remote_remove
  # ---------------------------------------------------------------------------

  describe '#remote_remove' do
    it 'removes the named remote' do
      described_instance.remote_remove('origin')
      expect(repo.remotes.map(&:name)).not_to include('origin')
    end
  end

  # ---------------------------------------------------------------------------
  # #config_remote
  # ---------------------------------------------------------------------------

  describe '#config_remote' do
    it 'includes the url key' do
      result = described_instance.config_remote('origin')
      expect(result).to have_key('url')
    end

    it 'includes the fetch key' do
      result = described_instance.config_remote('origin')
      expect(result).to have_key('fetch')
    end

    it 'returns an empty hash for an unknown remote name' do
      expect(described_instance.config_remote('nonexistent-remote')).to eq({})
    end
  end

  # ---------------------------------------------------------------------------
  # #remote (factory)
  # ---------------------------------------------------------------------------

  # ---------------------------------------------------------------------------
  # #remotes
  # ---------------------------------------------------------------------------

  describe '#remotes' do
    it 'includes each configured remote by name' do
      described_instance.remote_add('upstream', bare_dir)
      expect(described_instance.remotes.map(&:name)).to contain_exactly('origin', 'upstream')
    end

    context 'when the repository has no remotes' do
      before { described_instance.remote_remove('origin') }

      it 'returns an empty array' do
        expect(described_instance.remotes).to eq([])
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #remote_set_url
  # ---------------------------------------------------------------------------

  describe '#remote_set_url' do
    let(:other_dir) { Dir.mktmpdir('other_repo') }

    after { FileUtils.rm_rf(other_dir) }

    before { Git.init(other_dir, bare: true) }

    it 'updates the fetch URL for the named remote' do
      described_instance.remote_set_url('origin', other_dir)
      expect(described_instance.config_remote('origin')['url']).to eq(other_dir)
    end
  end

  # ---------------------------------------------------------------------------
  # #remote_set_branches
  # ---------------------------------------------------------------------------

  describe '#remote_set_branches' do
    it 'replaces the tracked branches for the remote' do
      described_instance.remote_set_branches('origin', 'main')
      expect(described_instance.config_remote('origin')['fetch']).to include('main')
    end

    it 'appends tracked branches when add: true' do
      described_instance.remote_set_branches('origin', 'main')
      described_instance.remote_set_branches('origin', 'develop', add: true)
      fetch_values = execution_context.command_capturing('config', '--get-all', 'remote.origin.fetch').stdout
      expect(fetch_values).to include('main').and include('develop')
    end
  end

  # ---------------------------------------------------------------------------
  # #ls_remote
  # ---------------------------------------------------------------------------

  describe '#ls_remote' do
    it 'contains a "branches" key with at least one entry for the pushed branch' do
      result = described_instance.ls_remote('origin')
      expect(result).to have_key('branches')
      expect(result['branches']).not_to be_empty
    end

    it 'contains a "head" key' do
      result = described_instance.ls_remote('origin')
      expect(result).to have_key('head')
    end
  end
end
