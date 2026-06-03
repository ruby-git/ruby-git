# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/remote_operations'

RSpec.describe Git::Repository::RemoteOperations, :integration do
  include_context 'in an empty repository'

  let(:execution_context) { Git::ExecutionContext::Repository.from_base(repo) }
  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  let(:bare_dir) { Dir.mktmpdir('bare_repo') }

  after do
    FileUtils.rm_rf(bare_dir)
  end

  before do
    write_file('README.md', "# Hello\n")
    repo.add('README.md')
    repo.commit('Initial commit')

    Git.init(bare_dir, bare: true)
    repo.add_remote('origin', bare_dir)
    repo.push('origin', 'main')
  end

  # ---------------------------------------------------------------------------
  # #fetch — basic invocations
  # ---------------------------------------------------------------------------

  describe '#fetch' do
    it 'returns a String' do
      result = described_instance.fetch('origin')
      expect(result).to be_a(String)
    end

    it 'uses "origin" as the default remote' do
      result = described_instance.fetch
      expect(result).to be_a(String)
    end

    it 'raises Git::FailedError when the remote does not exist' do
      expect { described_instance.fetch('nonexistent-remote') }
        .to raise_error(Git::FailedError, /nonexistent-remote/)
    end

    context 'when opts is passed as the first argument (Hash-only form)' do
      it 'returns a String when fetching without an explicit remote' do
        result = described_instance.fetch(prune: true)
        expect(result).to be_a(String)
      end
    end

    context 'with an unknown option key' do
      it 'raises ArgumentError before calling git' do
        expect { described_instance.fetch('origin', unknown_key: true) }
          .to raise_error(ArgumentError, /unknown_key/)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #push — basic invocations
  # ---------------------------------------------------------------------------

  describe '#push' do
    it 'returns a String' do
      result = described_instance.push('origin', 'main')
      expect(result).to be_a(String)
    end

    it 'raises Git::FailedError when the remote does not exist' do
      expect { described_instance.push('nonexistent-remote', 'main') }
        .to raise_error(Git::FailedError, /nonexistent-remote/)
    end

    context 'when branch is specified without a remote' do
      it 'raises ArgumentError' do
        expect { described_instance.push(nil, 'main') }
          .to raise_error(ArgumentError, /remote is required/)
      end
    end

    context 'with an unknown option key' do
      it 'raises ArgumentError before calling git' do
        expect { described_instance.push('origin', 'main', unknown_key: true) }
          .to raise_error(ArgumentError, /unknown_key/)
      end
    end

    context 'with tags: true' do
      before do
        repo.add_tag('v1.0')
      end

      it 'pushes refs and tags and returns a String' do
        result = described_instance.push('origin', 'main', tags: true)
        expect(result).to be_a(String)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #pull — basic invocations
  # ---------------------------------------------------------------------------

  describe '#pull' do
    it 'returns a String' do
      result = described_instance.pull('origin', 'main')
      expect(result).to be_a(String)
    end

    it 'raises ArgumentError when a branch is given without a remote' do
      expect { described_instance.pull(nil, 'main') }
        .to raise_error(ArgumentError, /You must specify a remote if a branch is specified/)
    end

    it 'raises Git::FailedError when the remote does not exist' do
      expect { described_instance.pull('nonexistent-remote', 'main') }
        .to raise_error(Git::FailedError, /nonexistent-remote/)
    end

    it 'raises ArgumentError before calling git when an unknown option is given' do
      expect { described_instance.pull('origin', 'main', unknown_opt: true) }
        .to raise_error(ArgumentError, /unknown_opt/)
    end
  end

  # ---------------------------------------------------------------------------
  # #add_remote — basic invocations
  # ---------------------------------------------------------------------------

  describe '#add_remote' do
    let(:remote_dir) { Dir.mktmpdir('remote_repo') }

    after do
      FileUtils.rm_rf(remote_dir)
    end

    before do
      Git.init(remote_dir, bare: true)
    end

    it 'returns Git::Remote' do
      result = described_instance.add_remote('secondary', remote_dir)
      expect(result).to be_a(Git::Remote)
      expect(result.name).to eq('secondary')
    end

    it 'registers the remote so it appears in the repository config' do
      described_instance.add_remote('secondary', remote_dir)
      expect(repo.remotes.map(&:name)).to include('secondary')
    end

    context 'with fetch: true' do
      it 'does not raise an error' do
        expect { described_instance.add_remote('secondary', remote_dir, fetch: true) }.not_to raise_error
      end
    end

    context 'with track: "main"' do
      it 'does not raise an error' do
        expect { described_instance.add_remote('secondary', remote_dir, track: 'main') }.not_to raise_error
      end
    end

    context 'with the deprecated :with_fetch alias' do
      it 'does not raise an error' do
        expect { described_instance.add_remote('secondary', remote_dir, with_fetch: true) }.not_to raise_error
      end
    end

    context 'with an unknown option key' do
      it 'raises ArgumentError before calling git' do
        expect { described_instance.add_remote('secondary', remote_dir, unknown_key: true) }
          .to raise_error(ArgumentError, /unknown_key/)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #remove_remote
  # ---------------------------------------------------------------------------

  describe '#remove_remote' do
    it 'removes the named remote' do
      described_instance.remove_remote('origin')
      expect(repo.remotes.map(&:name)).not_to include('origin')
    end

    it 'returns a Git::CommandLineResult' do
      result = described_instance.remove_remote('origin')
      expect(result).to be_a(Git::CommandLineResult)
    end

    it 'raises Git::FailedError when the remote does not exist' do
      expect { described_instance.remove_remote('nonexistent') }
        .to raise_error(Git::FailedError, /nonexistent/)
    end
  end

  # ---------------------------------------------------------------------------
  # #config_remote
  # ---------------------------------------------------------------------------

  describe '#config_remote' do
    it 'returns a Hash' do
      expect(described_instance.config_remote('origin')).to be_a(Hash)
    end

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

  describe '#remote' do
    it 'returns a Git::Remote for the named remote' do
      result = described_instance.remote('origin')
      expect(result).to be_a(Git::Remote)
      expect(result.name).to eq('origin')
    end

    it 'defaults to "origin" when no name is given' do
      result = described_instance.remote
      expect(result).to be_a(Git::Remote)
      expect(result.name).to eq('origin')
    end

    it 'populates url from the remote configuration' do
      result = described_instance.remote('origin')
      expect(result.url).to eq(bare_dir)
    end
  end

  # ---------------------------------------------------------------------------
  # #remotes
  # ---------------------------------------------------------------------------

  describe '#remotes' do
    it 'returns an Array of Git::Remote objects' do
      result = described_instance.remotes
      expect(result).to all(be_a(Git::Remote))
    end

    it 'includes each configured remote by name' do
      described_instance.add_remote('upstream', bare_dir)
      expect(described_instance.remotes.map(&:name)).to contain_exactly('origin', 'upstream')
    end

    context 'when the repository has no remotes' do
      before { described_instance.remove_remote('origin') }

      it 'returns an empty array' do
        expect(described_instance.remotes).to eq([])
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #set_remote_url
  # ---------------------------------------------------------------------------

  describe '#set_remote_url' do
    let(:other_dir) { Dir.mktmpdir('other_repo') }

    after { FileUtils.rm_rf(other_dir) }

    before { Git.init(other_dir, bare: true) }

    it 'updates the fetch URL for the named remote' do
      described_instance.set_remote_url('origin', other_dir)
      expect(described_instance.config_remote('origin')['url']).to eq(other_dir)
    end

    it 'returns a Git::Remote for the updated remote' do
      result = described_instance.set_remote_url('origin', other_dir)
      expect(result).to be_a(Git::Remote)
      expect(result.name).to eq('origin')
    end

    it 'raises Git::FailedError when the remote does not exist' do
      expect { described_instance.set_remote_url('nonexistent', other_dir) }
        .to raise_error(Git::FailedError)
    end
  end

  # ---------------------------------------------------------------------------
  # #remote_set_branches
  # ---------------------------------------------------------------------------

  describe '#remote_set_branches' do
    it 'returns nil' do
      expect(described_instance.remote_set_branches('origin', 'main')).to be_nil
    end

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

    it 'raises ArgumentError when no branches are given' do
      expect { described_instance.remote_set_branches('origin') }
        .to raise_error(ArgumentError, /branches are required/)
    end

    it 'raises Git::FailedError when the remote does not exist' do
      expect { described_instance.remote_set_branches('nonexistent', 'main') }
        .to raise_error(Git::FailedError)
    end
  end
end
