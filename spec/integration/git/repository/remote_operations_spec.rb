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
  # #remote_add — basic invocations
  # ---------------------------------------------------------------------------

  describe '#remote_add' do
    let(:remote_dir) { Dir.mktmpdir('remote_repo') }

    after do
      FileUtils.rm_rf(remote_dir)
    end

    before do
      Git.init(remote_dir, bare: true, initial_branch: 'main')
    end

    it 'registers the remote so it appears in the repository config' do
      described_instance.remote_add('secondary', remote_dir)
      expect(described_instance.remote_list.map(&:name)).to include('secondary')
    end
  end

  # ---------------------------------------------------------------------------
  # #remote_remove
  # ---------------------------------------------------------------------------

  describe '#remote_remove' do
    it 'removes the named remote' do
      described_instance.remote_remove('origin')
      expect(described_instance.remote_list.map(&:name)).not_to include('origin')
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
  # #remote_list
  # ---------------------------------------------------------------------------

  describe '#remote_list' do
    it 'returns one RemoteInfo per configured remote' do
      described_instance.remote_add('upstream', bare_dir)
      expect(described_instance.remote_list.map(&:name)).to contain_exactly('origin', 'upstream')
    end

    it 'returns RemoteInfo objects' do
      expect(described_instance.remote_list).to contain_exactly(be_a(Git::RemoteInfo))
    end

    it 'includes the fetch URL for the remote' do
      result = described_instance.remote_list.find { |r| r.name == 'origin' }
      expect(result.url).to contain_exactly(bare_dir)
    end

    it 'includes at least one fetch refspec for the remote' do
      result = described_instance.remote_list.find { |r| r.name == 'origin' }
      expect(result.fetch).not_to be_empty
    end

    context 'when no remotes are configured' do
      before { described_instance.remote_remove('origin') }

      it 'returns an empty array' do
        expect(described_instance.remote_list).to eq([])
      end
    end
  end

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
  # #remote_names
  # ---------------------------------------------------------------------------

  describe '#remote_names' do
    let(:slash_remote_dir) { Dir.mktmpdir('slash_remote') }

    before { Git.init(slash_remote_dir, bare: true, initial_branch: 'main') }

    after { FileUtils.rm_rf(slash_remote_dir) }

    it 'returns an Array<String> of remote names' do
      expect(described_instance.remote_names).to all(be_a(String))
    end

    it 'includes all configured remote names' do
      described_instance.remote_add('team/upstream', slash_remote_dir)
      expect(described_instance.remote_names).to contain_exactly('origin', 'team/upstream')
    end

    it 'preserves the slash in slash-containing remote names' do
      described_instance.remote_add('team/upstream', slash_remote_dir)
      expect(described_instance.remote_names).to include('team/upstream')
    end

    context 'when no remotes are configured' do
      before { described_instance.remote_remove('origin') }

      it 'returns an empty array' do
        expect(described_instance.remote_names).to eq([])
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #remote_set_url
  # ---------------------------------------------------------------------------

  describe '#remote_set_url' do
    let(:other_dir) { Dir.mktmpdir('other_repo') }

    after { FileUtils.rm_rf(other_dir) }

    before { Git.init(other_dir, bare: true, initial_branch: 'main') }

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
