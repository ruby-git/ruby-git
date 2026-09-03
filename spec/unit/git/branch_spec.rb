# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Branch do
  let(:execution_context) { instance_double(Git::ExecutionContext::Repository) }
  let(:base) { Git::Repository.new(execution_context: execution_context) }

  before { allow(Git::Deprecation).to receive(:warn) }

  describe '#initialize' do
    context 'with a BranchInfo object for a local branch' do
      subject(:branch) { described_class.new(base, branch_info) }

      let(:branch_info) do
        Git::BranchInfo.new(
          refname: 'feature/my-feature',
          target_oid: 'abc123',
          current: true,
          worktree_path: nil,
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
          worktree_path: nil,
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
          worktree_path: nil,
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
          worktree_path: nil,
          symref: nil,
          upstream: nil
        )
      end

      it 'emits a deprecation warning via Git::Deprecation.warn' do
        allow(base).to receive(:branch_delete).with('feature').and_return('')
        expect(Git::Deprecation).to receive(:warn).with(
          'Git::Branch#delete is deprecated and will be removed in v6.0.0. ' \
          'Use Git::Repository#branch_delete(name) or, for a remote-tracking branch, ' \
          'Git::Repository#branch_delete("remote/name", remotes: true) instead.'
        )
        delete_branch
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
          worktree_path: nil,
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
        worktree_path: nil,
        symref: nil,
        upstream: nil
      )
    end

    context 'when base is a Git::Repository and name matches current branch' do
      subject(:branch) { described_class.new(base, branch_info) }

      before { allow(base).to receive(:current_branch).and_return('feature') }

      it 'emits a deprecation warning via Git::Deprecation.warn' do
        expect(Git::Deprecation).to receive(:warn).with(
          'Git::Branch#current is deprecated and will be removed in v6.0.0. ' \
          'Use Git::Repository#current_branch == name instead.'
        )
        branch.current
      end

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
        worktree_path: nil,
        symref: nil,
        upstream: nil
      )
    end

    context 'when the branch contains the commit' do
      before { allow(base).to receive(:branch_contains).with('abc123', 'feature').and_return(['abc123']) }

      it 'emits a deprecation warning via Git::Deprecation.warn' do
        expect(Git::Deprecation).to receive(:warn).with(
          'Git::Branch#contains? is deprecated and will be removed in v6.0.0. ' \
          'Use !Git::Repository#branch_contains(commit, name).empty? instead.'
        )
        branch.contains?('abc123')
      end

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
  # #merge
  # ---------------------------------------------------------------------------

  describe '#merge' do
    subject(:branch) { described_class.new(base, branch_info) }

    let(:branch_info) do
      Git::BranchInfo.new(
        refname: 'feature',
        target_oid: nil,
        current: false,
        worktree_path: nil,
        symref: nil,
        upstream: nil
      )
    end

    context 'when a branch is given' do
      before do
        allow(base).to receive(:current_branch).and_return('main')
        allow(base).to receive(:branch_new).with('feature').and_return(command_result(''))
        allow(base).to receive(:checkout).and_return('')
        allow(base).to receive(:reset).with(nil, hard: true).and_return(command_result(''))
      end

      it 'emits a deprecation warning via Git::Deprecation.warn' do
        allow(base).to receive(:merge).with('other-branch', 'my message').and_return('merged')
        expect(Git::Deprecation).to receive(:warn).with(
          'Git::Branch#merge(branch) is deprecated and will be removed in v6.0.0. ' \
          'Use Git::Repository#merge_into(name, branch, message) instead. It takes an existing ' \
          'local branch; for a remote-tracking branch, create a local branch from it first.'
        )
        branch.merge('other-branch', 'my message')
      end

      it 'merges the given branch into this branch, then restores the original branch' do
        expect(base).to receive(:merge).with('other-branch', 'my message').and_return('merged')
        expect(base).to receive(:checkout).with('main').and_return('restored')
        expect(branch.merge('other-branch', 'my message')).to eq('restored')
      end

      context 'when the nested in_branch and checkout warnings are not stubbed' do
        let(:messages) { [] }

        # Route real warnings to a collector so the silence around the nested
        # deprecated call is exercised instead of bypassed by the stubbed
        # Git::Deprecation.warn
        around do |example|
          original_behavior = Git::Deprecation.behavior
          Git::Deprecation.behavior = ->(message, *) { messages << message }
          example.run
        ensure
          Git::Deprecation.behavior = original_behavior
        end

        before do
          allow(Git::Deprecation).to receive(:warn).and_call_original
          allow(base).to receive(:merge).with('other-branch', nil).and_return('merged')
        end

        it 'lets only the Git::Branch#merge(branch) warning escape' do
          branch.merge('other-branch')
          expect(messages).to contain_exactly(a_string_including('Git::Branch#merge(branch) is deprecated'))
        end
      end
    end

    context 'when no branch is given' do
      it 'emits a deprecation warning via Git::Deprecation.warn' do
        allow(base).to receive(:merge).with('feature').and_return('merged')
        expect(Git::Deprecation).to receive(:warn).with(
          'Git::Branch#merge with no arguments is deprecated and will be removed in v6.0.0. ' \
          'Use Git::Repository#merge(name) instead.'
        )
        branch.merge
      end

      it 'merges this branch into the current branch' do
        expect(base).to receive(:merge).with('feature').and_return('merged')
        expect(branch.merge).to eq('merged')
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
          worktree_path: nil,
          symref: nil,
          upstream: nil
        )
      end

      it 'emits a deprecation warning via Git::Deprecation.warn' do
        allow(base).to receive(:update_ref).with('feature', 'newcommit').and_return(command_result(''))
        expect(Git::Deprecation).to receive(:warn).with(
          'Git::Branch#update_ref is deprecated and will be removed in v6.0.0. ' \
          'Use Git::Repository#update_ref(name, commit) or, for a remote-tracking branch, ' \
          'Git::Repository#update_ref("remotes/remote/name", commit) instead.'
        )
        update
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
          worktree_path: nil,
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
        worktree_path: nil,
        symref: nil,
        upstream: nil
      )
    end

    context 'when branch_new succeeds' do
      it 'emits a deprecation warning via Git::Deprecation.warn' do
        allow(base).to receive(:branch_new).with('new-feature').and_return(command_result(''))
        expect(Git::Deprecation).to receive(:warn).with(
          'Git::Branch#create is deprecated and will be removed in v6.0.0. ' \
          'Use Git::Repository#branch_new instead.'
        )
        branch.create
      end

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
        worktree_path: nil,
        symref: nil,
        upstream: nil
      )
    end

    let(:gcommit_obj) { instance_double(Git::Object::Commit) }

    it 'emits a deprecation warning via Git::Deprecation.warn' do
      allow(base).to receive(:gcommit).with('feature').and_return(gcommit_obj)
      expect(Git::Deprecation).to receive(:warn).with(
        'Git::Branch#gcommit is deprecated and will be removed in v6.0.0. ' \
        'Use Git::Repository#gcommit(name) or, for a remote-tracking branch, ' \
        'Git::Repository#gcommit("remotes/remote/name") instead.'
      )
      branch.gcommit
    end

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
  # #stashes
  # ---------------------------------------------------------------------------

  describe '#stashes' do
    subject(:branch) { described_class.new(base, branch_info) }

    let(:branch_info) do
      Git::BranchInfo.new(
        refname: 'feature',
        target_oid: nil,
        current: false,
        worktree_path: nil,
        symref: nil,
        upstream: nil
      )
    end

    before { allow(base).to receive(:stashes_all).and_return([]) }

    it 'emits a deprecation warning via Git::Deprecation.warn' do
      expect(Git::Deprecation).to receive(:warn).with(a_string_including('Git::Branch#stashes'))
      branch.stashes
    end

    it 'returns a Git::Stashes for the branch repository' do
      allow(Git::Deprecation).to receive(:warn)
      expect(branch.stashes).to be_a(Git::Stashes)
    end

    it 'memoizes the result' do
      allow(Git::Deprecation).to receive(:warn)
      expect(branch.stashes).to be(branch.stashes)
    end

    it 'emits the deprecation warning on every call, including memoized calls' do
      expect(Git::Deprecation).to receive(:warn).with(a_string_including('Git::Branch#stashes')).twice
      branch.stashes
      branch.stashes
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
        worktree_path: nil,
        symref: nil,
        upstream: nil
      )
    end

    it 'emits a deprecation warning via Git::Deprecation.warn' do
      allow(base).to receive(:archive).and_return('out.tar')
      expect(Git::Deprecation).to receive(:warn).with(
        'Git::Branch#archive is deprecated and will be removed in v6.0.0. ' \
        'Use Git::Repository#archive(name, file, opts) or, for a remote-tracking branch, ' \
        'Git::Repository#archive("remotes/remote/name", file, opts) instead.'
      )
      branch.archive('out.tar', format: 'tar')
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
        worktree_path: nil,
        symref: nil,
        upstream: nil
      )
    end

    it 'emits a deprecation warning via Git::Deprecation.warn' do
      allow(base).to receive(:branch_new).with('feature').and_return(command_result(''))
      allow(base).to receive(:checkout).with('feature').and_return('')
      expect(Git::Deprecation).to receive(:warn).with(
        'Git::Branch#checkout is deprecated and will be removed in v6.0.0. ' \
        'Use Git::Repository#checkout(name) or, for a remote-tracking branch, ' \
        'Git::Repository#checkout("remotes/remote/name") instead. Git::Repository#checkout does not ' \
        'create a missing local branch (beyond the guess git makes from a unique remote-tracking ' \
        'branch); call Git::Repository#branch_new first unless Git::Repository#local_branch? is true.'
      )
      branch.checkout
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
        worktree_path: nil,
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
      it 'emits a deprecation warning via Git::Deprecation.warn' do
        allow(base).to receive(:commit_all).with('my message').and_return(command_result(''))
        expect(Git::Deprecation).to receive(:warn).with(
          'Git::Branch#in_branch is deprecated and will be removed in v6.0.0. ' \
          'Use Git::Repository#in_branch(name, message) instead. It takes an existing local ' \
          'branch; for a remote-tracking branch, create a local branch from it first.'
        )
        branch.in_branch('my message') { true }
      end

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

    context 'when the nested checkout warning is not stubbed' do
      let(:messages) { [] }

      # Route real warnings to a collector so the silence around the nested
      # deprecated call is exercised instead of bypassed by the stubbed
      # Git::Deprecation.warn
      around do |example|
        original_behavior = Git::Deprecation.behavior
        Git::Deprecation.behavior = ->(message, *) { messages << message }
        example.run
      ensure
        Git::Deprecation.behavior = original_behavior
      end

      before do
        allow(Git::Deprecation).to receive(:warn).and_call_original
        allow(base).to receive(:reset).with(nil, hard: true).and_return(command_result(''))
      end

      it 'lets only the Git::Branch#in_branch warning escape' do
        branch.in_branch { false }
        expect(messages).to contain_exactly(a_string_including('Git::Branch#in_branch is deprecated'))
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
        worktree_path: nil,
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
        worktree_path: nil,
        symref: nil,
        upstream: nil
      )
    end

    it 'returns the full refname as a string' do
      expect(branch.to_s).to eq('feature')
    end
  end
end
