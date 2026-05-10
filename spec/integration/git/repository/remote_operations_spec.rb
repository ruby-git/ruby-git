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

    it 'succeeds when fetching from a valid remote' do
      expect { described_instance.fetch('origin') }.not_to raise_error
    end

    it 'uses "origin" as the default remote' do
      expect { described_instance.fetch }.not_to raise_error
    end

    it 'raises Git::FailedError when the remote does not exist' do
      expect { described_instance.fetch('nonexistent-remote') }.to raise_error(Git::FailedError)
    end

    context 'when opts is passed as the first argument (Hash-only form)' do
      it 'does not raise when fetching without an explicit remote' do
        expect { described_instance.fetch(prune: true) }.not_to raise_error
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

    it 'succeeds when pushing to a valid remote' do
      expect { described_instance.push('origin', 'main') }.not_to raise_error
    end

    it 'raises Git::FailedError when the remote does not exist' do
      expect { described_instance.push('nonexistent-remote', 'main') }
        .to raise_error(Git::FailedError)
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

    it 'succeeds when the local branch is already up to date' do
      expect { described_instance.pull('origin', 'main') }.not_to raise_error
    end

    it 'raises ArgumentError when a branch is given without a remote' do
      expect { described_instance.pull(nil, 'main') }
        .to raise_error(ArgumentError, /You must specify a remote if a branch is specified/)
    end

    it 'raises Git::FailedError when the remote does not exist' do
      expect { described_instance.pull('nonexistent-remote', 'main') }.to raise_error(Git::FailedError)
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
        .to raise_error(Git::FailedError)
    end
  end
end
