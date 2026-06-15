# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Branch do
  let(:execution_context) { instance_double(Git::ExecutionContext::Repository) }
  let(:base) { Git::Repository.new(execution_context: execution_context) }

  describe '#initialize' do
    context 'with a BranchInfo object for a local branch' do
      subject(:branch) { described_class.new(base, branch_info) }

      let(:branch_info) do
        Git::BranchInfo.new(
          refname: 'feature/my-feature',
          target_oid: 'abc123',
          current: true,
          worktree: false,
          symref: nil,
          upstream: nil
        )
      end

      it 'sets the full refname' do
        expect(branch.full).to eq('feature/my-feature')
      end

      it 'sets the short name' do
        expect(branch.name).to eq('feature/my-feature')
      end

      it 'has no remote' do
        expect(branch.remote).to be_nil
      end
    end

    context 'with a BranchInfo object for a remote branch' do
      subject(:branch) { described_class.new(base, branch_info) }

      let(:branch_info) do
        Git::BranchInfo.new(
          refname: 'remotes/origin/main',
          target_oid: 'abc123',
          current: false,
          worktree: false,
          symref: nil,
          upstream: nil
        )
      end

      let(:remote_config) { { 'url' => 'https://github.com/test/repo.git' } }

      before do
        allow(base).to receive(:config_remote).with('origin').and_return(remote_config)
      end

      it 'sets the full refname' do
        expect(branch.full).to eq('remotes/origin/main')
      end

      it 'sets the short name without remote prefix' do
        expect(branch.name).to eq('main')
      end

      it 'creates a remote object' do
        expect(branch.remote).to be_a(Git::Remote)
        expect(branch.remote.name).to eq('origin')
      end
    end

    context 'with a String (legacy path)' do
      subject(:branch) { described_class.new(base, 'remotes/origin/develop') }

      let(:remote_config) { { 'url' => 'https://github.com/test/repo.git' } }

      before do
        allow(base).to receive(:config_remote).with('origin').and_return(remote_config)
      end

      it 'sets the full refname' do
        expect(branch.full).to eq('remotes/origin/develop')
      end

      it 'sets the short name without remote prefix' do
        expect(branch.name).to eq('develop')
      end

      it 'creates a remote object' do
        expect(branch.remote).to be_a(Git::Remote)
        expect(branch.remote.name).to eq('origin')
      end
    end

    context 'when initialized from either BranchInfo or String with the same refname' do
      let(:refname) { 'remotes/upstream/feature/test' }
      let(:remote_config) { { 'url' => 'https://github.com/test/repo.git' } }

      let(:branch_info) do
        Git::BranchInfo.new(
          refname: refname,
          target_oid: 'abc123',
          current: false,
          worktree: false,
          symref: nil,
          upstream: nil
        )
      end

      let(:branch_from_info) { described_class.new(base, branch_info) }
      let(:branch_from_string) { described_class.new(base, refname) }

      before do
        allow(base).to receive(:config_remote).with('upstream').and_return(remote_config)
      end

      it 'produces equivalent full refname' do
        expect(branch_from_info.full).to eq(branch_from_string.full)
      end

      it 'produces equivalent short name' do
        expect(branch_from_info.name).to eq(branch_from_string.name)
      end

      it 'produces equivalent remote name' do
        expect(branch_from_info.remote.name).to eq(branch_from_string.remote.name)
      end
    end
  end

  describe '#delete' do
    context 'with a local branch' do
      subject(:delete_branch) { described_class.new(base, branch_info).delete }

      let(:branch_info) do
        Git::BranchInfo.new(
          refname: 'feature',
          target_oid: 'abc123',
          current: false,
          worktree: false,
          symref: nil,
          upstream: nil
        )
      end

      it 'deletes the local branch by short name' do
        expect(base).to receive(:branch_delete).with('feature').and_return('Deleted branch feature.')

        expect(delete_branch).to eq('Deleted branch feature.')
      end
    end

    context 'with a remote-tracking branch' do
      subject(:delete_branch) { described_class.new(base, branch_info).delete }

      let(:branch_info) do
        Git::BranchInfo.new(
          refname: 'remotes/origin/feature',
          target_oid: 'abc123',
          current: false,
          worktree: false,
          symref: nil,
          upstream: nil
        )
      end

      let(:remote_config) { { 'url' => 'https://github.com/test/repo.git' } }

      before do
        allow(base).to receive(:config_remote).with('origin').and_return(remote_config)
      end

      it 'deletes the remote-tracking ref instead of a local branch with the same short name' do
        expect(base).to receive(:branch_delete)
          .with('origin/feature', remotes: true)
          .and_return('Deleted remote-tracking branch origin/feature.')

        expect(delete_branch).to eq('Deleted remote-tracking branch origin/feature.')
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #current
  # ---------------------------------------------------------------------------

  describe '#current' do
    let(:branch_info) do
      Git::BranchInfo.new(
        refname: 'feature',
        target_oid: nil,
        current: false,
        worktree: false,
        symref: nil,
        upstream: nil
      )
    end

    context 'when base is a Git::Repository and name matches current branch' do
      subject(:branch) { described_class.new(base, branch_info) }

      before { allow(base).to receive(:current_branch).and_return('feature') }

      it 'returns true' do
        expect(branch.current).to be true
      end
    end

    context 'when base is a Git::Repository and name does not match current branch' do
      subject(:branch) { described_class.new(base, branch_info) }

      before { allow(base).to receive(:current_branch).and_return('main') }

      it 'returns false' do
        expect(branch.current).to be false
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #contains?
  # ---------------------------------------------------------------------------

  describe '#contains?' do
    subject(:branch) { described_class.new(base, branch_info) }

    let(:branch_info) do
      Git::BranchInfo.new(
        refname: 'feature',
        target_oid: nil,
        current: false,
        worktree: false,
        symref: nil,
        upstream: nil
      )
    end

    context 'when the branch contains the commit' do
      before { allow(base).to receive(:branch_contains).with('abc123', 'feature').and_return(['abc123']) }

      it 'returns true' do
        expect(branch.contains?('abc123')).to be true
      end
    end

    context 'when the branch does not contain the commit' do
      before { allow(base).to receive(:branch_contains).with('abc123', 'feature').and_return([]) }

      it 'returns false' do
        expect(branch.contains?('abc123')).to be false
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #update_ref
  # ---------------------------------------------------------------------------

  describe '#update_ref' do
    context 'with a local branch' do
      subject(:update) { described_class.new(base, branch_info).update_ref('newcommit') }

      let(:branch_info) do
        Git::BranchInfo.new(
          refname: 'feature',
          target_oid: nil,
          current: false,
          worktree: false,
          symref: nil,
          upstream: nil
        )
      end

      it 'calls update_ref with the short branch name and commit' do
        expect(base).to receive(:update_ref).with('feature', 'newcommit').and_return(command_result(''))
        update
      end
    end

    context 'with a remote-tracking branch' do
      subject(:update) { described_class.new(base, branch_info).update_ref('newcommit') }

      let(:remote_config) { { 'url' => 'https://github.com/test/repo.git' } }
      let(:branch_info) do
        Git::BranchInfo.new(
          refname: 'remotes/origin/feature',
          target_oid: nil,
          current: false,
          worktree: false,
          symref: nil,
          upstream: nil
        )
      end

      before do
        allow(base).to receive(:config_remote).with('origin').and_return(remote_config)
      end

      it 'calls update_ref with the remotes/<remote>/<name> path' do
        expect(base).to receive(:update_ref).with('remotes/origin/feature', 'newcommit').and_return(command_result(''))
        update
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #create
  # ---------------------------------------------------------------------------

  describe '#create' do
    subject(:branch) { described_class.new(base, branch_info) }

    let(:branch_info) do
      Git::BranchInfo.new(
        refname: 'new-feature',
        target_oid: nil,
        current: false,
        worktree: false,
        symref: nil,
        upstream: nil
      )
    end

    context 'when branch_new succeeds' do
      it 'calls branch_new on the repository' do
        expect(base).to receive(:branch_new).with('new-feature').and_return(command_result(''))
        branch.create
      end
    end

    context 'when branch_new raises a StandardError' do
      before do
        allow(base).to receive(:branch_new).with('new-feature').and_raise(StandardError, 'branch already exists')
      end

      it 'silently rescues and returns nil' do
        expect(branch.create).to be_nil
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #gcommit
  # ---------------------------------------------------------------------------

  describe '#gcommit' do
    subject(:branch) { described_class.new(base, branch_info) }

    let(:branch_info) do
      Git::BranchInfo.new(
        refname: 'feature',
        target_oid: 'abc123',
        current: false,
        worktree: false,
        symref: nil,
        upstream: nil
      )
    end

    let(:gcommit_obj) { instance_double(Git::Object::Commit) }

    it 'delegates to base.gcommit with the full refname' do
      allow(base).to receive(:gcommit).with('feature').and_return(gcommit_obj)
      expect(branch.gcommit).to be(gcommit_obj)
    end

    it 'memoizes the result' do
      expect(base).to receive(:gcommit).with('feature').once.and_return(gcommit_obj)
      branch.gcommit
      branch.gcommit
    end
  end

  # ---------------------------------------------------------------------------
  # #archive
  # ---------------------------------------------------------------------------

  describe '#archive' do
    subject(:branch) { described_class.new(base, branch_info) }

    let(:branch_info) do
      Git::BranchInfo.new(
        refname: 'feature',
        target_oid: nil,
        current: false,
        worktree: false,
        symref: nil,
        upstream: nil
      )
    end

    it 'delegates to base.archive with full refname, file path, and options' do
      expect(base).to receive(:archive).with('feature', 'out.tar', { format: 'tar' }).and_return('out.tar')
      branch.archive('out.tar', format: 'tar')
    end
  end

  # ---------------------------------------------------------------------------
  # #checkout
  # ---------------------------------------------------------------------------

  describe '#checkout' do
    subject(:branch) { described_class.new(base, branch_info) }

    let(:branch_info) do
      Git::BranchInfo.new(
        refname: 'feature',
        target_oid: nil,
        current: false,
        worktree: false,
        symref: nil,
        upstream: nil
      )
    end

    it 'calls check_if_create then checks out the full refname' do
      allow(base).to receive(:branch_new).with('feature').and_return(command_result(''))
      expect(base).to receive(:checkout).with('feature').and_return('')
      branch.checkout
    end
  end

  # ---------------------------------------------------------------------------
  # #in_branch
  # ---------------------------------------------------------------------------

  describe '#in_branch' do
    subject(:branch) { described_class.new(base, branch_info) }

    let(:branch_info) do
      Git::BranchInfo.new(
        refname: 'feature',
        target_oid: nil,
        current: false,
        worktree: false,
        symref: nil,
        upstream: nil
      )
    end

    before do
      allow(base).to receive(:current_branch).and_return('main')
      allow(base).to receive(:branch_new).with('feature').and_return(command_result(''))
      allow(base).to receive(:checkout).and_return('')
    end

    context 'when block returns truthy' do
      it 'commits all changes and restores the original branch' do
        allow(base).to receive(:commit_all).with('my message').and_return(command_result(''))
        expect(base).to receive(:checkout).with('main').and_return('')
        branch.in_branch('my message') { true }
      end
    end

    context 'when block returns falsy' do
      it 'hard-resets and restores the original branch' do
        allow(base).to receive(:reset).with(nil, hard: true).and_return(command_result(''))
        expect(base).to receive(:checkout).with('main').and_return('')
        branch.in_branch { false }
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #to_a
  # ---------------------------------------------------------------------------

  describe '#to_a' do
    subject(:branch) { described_class.new(base, branch_info) }

    let(:branch_info) do
      Git::BranchInfo.new(
        refname: 'feature',
        target_oid: nil,
        current: false,
        worktree: false,
        symref: nil,
        upstream: nil
      )
    end

    it 'returns a single-element array with the full refname' do
      expect(branch.to_a).to eq(['feature'])
    end
  end

  # ---------------------------------------------------------------------------
  # #to_s
  # ---------------------------------------------------------------------------

  describe '#to_s' do
    subject(:branch) { described_class.new(base, branch_info) }

    let(:branch_info) do
      Git::BranchInfo.new(
        refname: 'feature',
        target_oid: nil,
        current: false,
        worktree: false,
        symref: nil,
        upstream: nil
      )
    end

    it 'returns the full refname as a string' do
      expect(branch.to_s).to eq('feature')
    end
  end
end
