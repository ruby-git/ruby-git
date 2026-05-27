# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Branches do
  def make_branch_info(refname:, current: false)
    Git::BranchInfo.new(
      refname: refname,
      target_oid: nil,
      current: current,
      worktree: false,
      symref: nil,
      upstream: nil
    )
  end

  let(:local_info) { make_branch_info(refname: 'main', current: true) }
  let(:remote_info) { make_branch_info(refname: 'remotes/origin/main') }

  let(:local_branch) do
    instance_double(Git::Branch, full: 'main', name: 'main', remote: nil, current: true, to_s: 'main')
  end
  let(:remote_branch) do
    instance_double(
      Git::Branch,
      full: 'remotes/origin/main', name: 'main',
      remote: instance_double(Git::Remote), current: false, to_s: 'remotes/origin/main'
    )
  end

  # ---------------------------------------------------------------------------
  # #initialize
  # ---------------------------------------------------------------------------

  describe '#initialize' do
    context 'when passed a Git::Repository' do
      let(:base) { instance_double(Git::Repository) }

      before do
        allow(base).to receive(:is_a?).with(Git::Base).and_return(false)
        allow(base).to receive(:branches_all).and_return([local_info, remote_info])
        allow(Git::Branch).to receive(:new).with(base, local_info).and_return(local_branch)
        allow(Git::Branch).to receive(:new).with(base, remote_info).and_return(remote_branch)
      end

      it 'calls branches_all directly on the base' do
        expect(base).to receive(:branches_all).and_return([local_info, remote_info])
        described_class.new(base)
      end

      it 'creates a Git::Branch for each BranchInfo with the original base' do
        expect(Git::Branch).to receive(:new).with(base, local_info).and_return(local_branch)
        expect(Git::Branch).to receive(:new).with(base, remote_info).and_return(remote_branch)
        described_class.new(base)
      end

      it 'returns an instance of Git::Branches' do
        expect(described_class.new(base)).to be_a(described_class)
      end
    end

    context 'when passed a Git::Base' do
      let(:facade_repo) { instance_double(Git::Repository) }
      let(:base) { instance_double(Git::Base) }

      before do
        allow(base).to receive(:is_a?).with(Git::Base).and_return(true)
        allow(base).to receive(:facade_repository).and_return(facade_repo)
        allow(facade_repo).to receive(:branches_all).and_return([local_info])
        allow(Git::Branch).to receive(:new).with(base, local_info).and_return(local_branch)
      end

      it 'calls branches_all on the facade_repository, not on base directly' do
        expect(facade_repo).to receive(:branches_all).and_return([local_info])
        described_class.new(base)
      end

      it 'creates Git::Branch objects with the original base (not the facade repository)' do
        expect(Git::Branch).to receive(:new).with(base, local_info).and_return(local_branch)
        described_class.new(base)
      end

      it 'returns an instance of Git::Branches' do
        expect(described_class.new(base)).to be_a(described_class)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Collection helpers: a Git::Branches with two known branches
  # ---------------------------------------------------------------------------

  let(:repo_base) { instance_double(Git::Repository) }
  let(:collection) { described_class.new(repo_base) }

  before do
    allow(repo_base).to receive(:is_a?).with(Git::Base).and_return(false)
    allow(repo_base).to receive(:branches_all).and_return([local_info, remote_info])
    allow(Git::Branch).to receive(:new).with(repo_base, local_info).and_return(local_branch)
    allow(Git::Branch).to receive(:new).with(repo_base, remote_info).and_return(remote_branch)
  end

  # ---------------------------------------------------------------------------
  # #local
  # ---------------------------------------------------------------------------

  describe '#local' do
    subject(:result) { collection.local }

    it 'returns only non-remote branches' do
      expect(result).to eq([local_branch])
    end

    it 'excludes remote-tracking branches' do
      expect(result).not_to include(remote_branch)
    end
  end

  # ---------------------------------------------------------------------------
  # #remote
  # ---------------------------------------------------------------------------

  describe '#remote' do
    subject(:result) { collection.remote }

    it 'returns only remote-tracking branches' do
      expect(result).to eq([remote_branch])
    end

    it 'excludes local branches' do
      expect(result).not_to include(local_branch)
    end
  end

  # ---------------------------------------------------------------------------
  # #size
  # ---------------------------------------------------------------------------

  describe '#size' do
    it 'returns the total number of branches' do
      expect(collection.size).to eq(2)
    end

    context 'when the branch list is empty' do
      let(:empty_base) { instance_double(Git::Repository) }
      let(:empty_collection) { described_class.new(empty_base) }

      before do
        allow(empty_base).to receive(:is_a?).with(Git::Base).and_return(false)
        allow(empty_base).to receive(:branches_all).and_return([])
      end

      it 'returns 0' do
        expect(empty_collection.size).to eq(0)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #each
  # ---------------------------------------------------------------------------

  describe '#each' do
    it 'yields every branch in the collection' do
      yielded = collection.map { |b| b }
      expect(yielded).to contain_exactly(local_branch, remote_branch)
    end

    it 'returns an Enumerator when called without a block' do
      expect(collection.each).to be_an(Enumerator)
    end
  end

  # ---------------------------------------------------------------------------
  # #[]
  # ---------------------------------------------------------------------------

  describe '#[]' do
    context 'with the exact refname of a local branch' do
      it 'returns the matching branch' do
        expect(collection['main']).to eq(local_branch)
      end
    end

    context 'with the full refname of a remote-tracking branch' do
      it 'returns the matching remote branch' do
        expect(collection['remotes/origin/main']).to eq(remote_branch)
      end
    end

    context 'with the short form of a remote-tracking branch (omitting "remotes/")' do
      it 'returns the remote branch' do
        expect(collection['origin/main']).to eq(remote_branch)
      end

      it 'does not change the collection size' do
        expect { collection['origin/main'] }.not_to change(collection, :size)
      end

      it 'does not duplicate branches in enumeration' do
        collection['origin/main']

        expect(collection.map(&:full)).to contain_exactly('main', 'remotes/origin/main')
      end
    end

    context 'with an unknown branch name' do
      it 'returns nil' do
        expect(collection['nonexistent']).to be_nil
      end
    end

    context 'with a non-String argument' do
      it 'coerces to string via to_s and returns the matching branch' do
        expect(collection[:main]).to eq(local_branch)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #to_s
  # ---------------------------------------------------------------------------

  describe '#to_s' do
    subject(:result) { collection.to_s }

    it 'includes each branch name' do
      expect(result).to include('main')
      expect(result).to include('remotes/origin/main')
    end

    it 'marks the current branch with "* "' do
      expect(result).to include('* main')
    end

    it 'marks non-current branches with two spaces' do
      expect(result).to include('  remotes/origin/main')
    end
  end
end
