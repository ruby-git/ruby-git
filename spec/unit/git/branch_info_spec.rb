# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::BranchInfo do
  describe '#initialize' do
    it 'raises when remote_name is given for a local branch refname' do
      expect do
        described_class.new(
          refname: 'refs/heads/main',
          target_oid: 'abc123',
          current: false,
          worktree_path: nil,
          symref: nil,
          upstream: nil,
          remote_name: 'origin'
        )
      end.to raise_error(ArgumentError, /remote_name must be nil for local branch refname/)
    end

    it 'raises when remote_name is nil for a remote-tracking branch refname' do
      expect do
        described_class.new(
          refname: 'refs/remotes/origin/main',
          target_oid: 'abc123',
          current: false,
          worktree_path: nil,
          symref: nil,
          upstream: nil,
          remote_name: nil
        )
      end.to raise_error(ArgumentError, /remote_name must be a non-empty String for remote-tracking refname/)
    end

    it 'raises when remote_name is empty for a remote-tracking branch refname' do
      expect do
        described_class.new(
          refname: 'refs/remotes/origin/main',
          target_oid: 'abc123',
          current: false,
          worktree_path: nil,
          symref: nil,
          upstream: nil,
          remote_name: ''
        )
      end.to raise_error(ArgumentError, /remote_name must be a non-empty String for remote-tracking refname/)
    end

    it 'raises when remote_name is not a String for a remote-tracking branch refname' do
      expect do
        described_class.new(
          refname: 'refs/remotes/origin/main',
          target_oid: 'abc123',
          current: false,
          worktree_path: nil,
          symref: nil,
          upstream: nil,
          remote_name: :origin
        )
      end.to raise_error(ArgumentError, /remote_name must be a non-empty String for remote-tracking refname/)
    end

    it 'raises when remote_name does not match the remote-tracking branch refname' do
      expect do
        described_class.new(
          refname: 'refs/remotes/team/upstream/main',
          target_oid: 'abc123',
          current: false,
          worktree_path: nil,
          symref: nil,
          upstream: nil,
          remote_name: 'origin'
        )
      end.to raise_error(ArgumentError, /remote_name must match remote-tracking refname/)
    end
  end

  describe 'attributes' do
    subject(:branch_info) do
      described_class.new(
        refname: 'main',
        target_oid: 'abc123def456789012345678901234567890abcd',
        current: true,
        worktree_path: nil,
        symref: nil,
        upstream: nil
      )
    end

    it 'exposes refname' do
      expect(branch_info.refname).to eq('main')
    end

    it 'exposes current' do
      expect(branch_info.current).to be true
    end

    it 'exposes worktree_path' do
      expect(branch_info.worktree_path).to be_nil
    end

    it 'exposes symref' do
      expect(branch_info.symref).to be_nil
    end

    it 'exposes target_oid' do
      expect(branch_info.target_oid).to eq('abc123def456789012345678901234567890abcd')
    end

    it 'exposes upstream' do
      expect(branch_info.upstream).to be_nil
    end

    it 'exposes an explicit remote_name' do
      branch_info = described_class.new(
        refname: 'refs/remotes/team/upstream/main',
        target_oid: 'abc123',
        current: false,
        worktree_path: nil,
        symref: nil,
        upstream: nil,
        remote_name: 'team/upstream'
      )

      expect(branch_info.remote_name).to eq('team/upstream')
    end
  end

  describe '#current?' do
    it 'returns true when current is true' do
      branch_info = described_class.new(
        refname: 'main', target_oid: 'abc123', current: true, worktree_path: nil,
        symref: nil, upstream: nil
      )
      expect(branch_info.current?).to be true
    end

    it 'returns false when current is false' do
      branch_info = described_class.new(
        refname: 'main', target_oid: 'abc123', current: false, worktree_path: nil,
        symref: nil, upstream: nil
      )
      expect(branch_info.current?).to be false
    end
  end

  describe '#other_worktree?' do
    it 'returns true when worktree_path is non-nil' do
      branch_info = described_class.new(
        refname: 'feature', target_oid: 'abc123', current: false, worktree_path: '/path/to/worktree',
        symref: nil, upstream: nil
      )
      expect(branch_info.other_worktree?).to be true
    end

    it 'returns false when worktree_path is nil' do
      branch_info = described_class.new(
        refname: 'feature', target_oid: 'abc123', current: false, worktree_path: nil,
        symref: nil, upstream: nil
      )
      expect(branch_info.other_worktree?).to be false
    end
  end

  describe '#symref?' do
    it 'returns true when symref is present' do
      branch_info = described_class.new(
        refname: 'HEAD', target_oid: 'abc123', current: false, worktree_path: nil,
        symref: 'refs/heads/main', upstream: nil
      )
      expect(branch_info.symref?).to be true
    end

    it 'returns false when symref is nil' do
      branch_info = described_class.new(
        refname: 'main', target_oid: 'abc123', current: false, worktree_path: nil,
        symref: nil, upstream: nil
      )
      expect(branch_info.symref?).to be false
    end
  end

  describe '#detached?' do
    it 'always returns false' do
      branch_info = described_class.new(
        refname: 'main', target_oid: 'abc123', current: false, worktree_path: nil,
        symref: nil, upstream: nil
      )
      expect(branch_info.detached?).to be false
    end
  end

  describe '#unborn?' do
    it 'returns true when target_oid is nil' do
      branch_info = described_class.new(
        refname: 'main', target_oid: nil, current: true, worktree_path: nil, symref: nil, upstream: nil
      )
      expect(branch_info.unborn?).to be true
    end

    it 'returns false when target_oid is present' do
      branch_info = described_class.new(
        refname: 'main', target_oid: 'abc123', current: false, worktree_path: nil,
        symref: nil, upstream: nil
      )
      expect(branch_info.unborn?).to be false
    end
  end

  describe '#remote?' do
    context 'with local branch' do
      it 'returns false for simple branch name' do
        branch_info = described_class.new(
          refname: 'main', target_oid: 'abc123', current: false, worktree_path: nil,
          symref: nil, upstream: nil
        )
        expect(branch_info.remote?).to be false
      end

      it 'returns false for branch with slashes' do
        branch_info = described_class.new(
          refname: 'feature/my-feature', target_oid: 'abc123', current: false, worktree_path: nil,
          symref: nil, upstream: nil
        )
        expect(branch_info.remote?).to be false
      end

      it 'returns false for a remotes-prefixed branch name without a branch segment' do
        branch_info = described_class.new(
          refname: 'remotes/foo', target_oid: 'abc123', current: false, worktree_path: nil,
          symref: nil, upstream: nil
        )
        expect(branch_info.remote?).to be false
      end
    end

    context 'with remote-tracking branch' do
      it 'returns true for remotes/origin/main' do
        branch_info = described_class.new(
          refname: 'remotes/origin/main', target_oid: 'abc123', current: false, worktree_path: nil,
          symref: nil, upstream: nil
        )
        expect(branch_info.remote?).to be true
      end

      it 'returns true for refs/remotes/origin/main' do
        branch_info = described_class.new(
          refname: 'refs/remotes/origin/main', target_oid: 'abc123', current: false, worktree_path: nil,
          symref: nil, upstream: nil
        )
        expect(branch_info.remote?).to be true
      end
    end
  end

  describe '#remote_name' do
    context 'with local branch' do
      it 'returns nil for simple branch name' do
        branch_info = described_class.new(
          refname: 'main', target_oid: 'abc123', current: false, worktree_path: nil,
          symref: nil, upstream: nil
        )
        expect(branch_info.remote_name).to be_nil
      end

      it 'returns nil for branch with slashes' do
        branch_info = described_class.new(
          refname: 'feature/my-feature', target_oid: 'abc123', current: false, worktree_path: nil,
          symref: nil, upstream: nil
        )
        expect(branch_info.remote_name).to be_nil
      end

      it 'returns nil for a refs/remotes-prefixed branch name without a branch segment' do
        branch_info = described_class.new(
          refname: 'refs/remotes/main', target_oid: 'abc123', current: false, worktree_path: nil,
          symref: nil, upstream: nil
        )
        expect(branch_info.remote_name).to be_nil
      end
    end

    context 'with remote-tracking branch' do
      it 'extracts remote name from remotes/origin/main' do
        branch_info = described_class.new(
          refname: 'remotes/origin/main', target_oid: 'abc123', current: false, worktree_path: nil,
          symref: nil, upstream: nil
        )
        expect(branch_info.remote_name).to eq('origin')
      end

      it 'extracts remote name from refs/remotes/origin/main' do
        branch_info = described_class.new(
          refname: 'refs/remotes/origin/main', target_oid: 'abc123', current: false, worktree_path: nil,
          symref: nil, upstream: nil
        )
        expect(branch_info.remote_name).to eq('origin')
      end

      it 'extracts remote name from remotes/upstream/feature' do
        branch_info = described_class.new(
          refname: 'remotes/upstream/feature', target_oid: 'abc123', current: false, worktree_path: nil,
          symref: nil, upstream: nil
        )
        expect(branch_info.remote_name).to eq('upstream')
      end
    end
  end

  describe '#short_name' do
    context 'with local branch' do
      it 'returns the branch name for simple branch' do
        branch_info = described_class.new(
          refname: 'main', target_oid: 'abc123', current: false, worktree_path: nil,
          symref: nil, upstream: nil
        )
        expect(branch_info.short_name).to eq('main')
      end

      it 'returns the branch name for refs/heads/ prefixed refname' do
        branch_info = described_class.new(
          refname: 'refs/heads/main', target_oid: 'abc123', current: false, worktree_path: nil,
          symref: nil, upstream: nil
        )
        expect(branch_info.short_name).to eq('main')
      end

      it 'returns nil for remote_name for refs/heads/ prefixed refname' do
        branch_info = described_class.new(
          refname: 'refs/heads/main', target_oid: 'abc123', current: false, worktree_path: nil,
          symref: nil, upstream: nil
        )
        expect(branch_info.remote_name).to be_nil
      end

      it 'returns false for remote? for refs/heads/ prefixed refname' do
        branch_info = described_class.new(
          refname: 'refs/heads/main', target_oid: 'abc123', current: false, worktree_path: nil,
          symref: nil, upstream: nil
        )
        expect(branch_info.remote?).to be false
      end

      it 'returns the full name for branch with slashes' do
        branch_info = described_class.new(
          refname: 'feature/my-feature', target_oid: 'abc123', current: false, worktree_path: nil,
          symref: nil, upstream: nil
        )
        expect(branch_info.short_name).to eq('feature/my-feature')
      end

      it 'returns the full name for deeply nested branch' do
        branch_info = described_class.new(
          refname: 'feature/team/project/task', target_oid: 'abc123', current: false, worktree_path: nil,
          symref: nil, upstream: nil
        )
        expect(branch_info.short_name).to eq('feature/team/project/task')
      end

      it 'returns the full name for a refs/remotes-prefixed branch name without a branch segment' do
        branch_info = described_class.new(
          refname: 'refs/remotes/main', target_oid: 'abc123', current: false, worktree_path: nil,
          symref: nil, upstream: nil
        )
        expect(branch_info.short_name).to eq('refs/remotes/main')
      end
    end

    context 'with remote-tracking branch' do
      it 'extracts branch name from remotes/origin/main' do
        branch_info = described_class.new(
          refname: 'remotes/origin/main', target_oid: 'abc123', current: false, worktree_path: nil,
          symref: nil, upstream: nil
        )
        expect(branch_info.short_name).to eq('main')
      end

      it 'extracts branch name from refs/remotes/origin/main' do
        branch_info = described_class.new(
          refname: 'refs/remotes/origin/main', target_oid: 'abc123', current: false, worktree_path: nil,
          symref: nil, upstream: nil
        )
        expect(branch_info.short_name).to eq('main')
      end

      it 'preserves slashes in remote branch name' do
        branch_info = described_class.new(
          refname: 'remotes/origin/feature/my-feature', target_oid: 'abc123', current: false,
          worktree_path: nil, symref: nil, upstream: nil
        )
        expect(branch_info.short_name).to eq('feature/my-feature')
      end

      it 'derives branch name from explicit slash remote name' do
        branch_info = described_class.new(
          refname: 'refs/remotes/team/upstream/feature/foo',
          target_oid: 'abc123',
          current: false,
          worktree_path: nil,
          symref: nil,
          upstream: nil,
          remote_name: 'team/upstream'
        )

        expect(branch_info.short_name).to eq('feature/foo')
      end
    end
  end

  describe '#to_s' do
    it 'returns the refname' do
      branch_info = described_class.new(
        refname: 'main', target_oid: 'abc123', current: true, worktree_path: nil,
        symref: nil, upstream: nil
      )
      expect(branch_info.to_s).to eq('main')
    end

    it 'returns full refname for remote branches' do
      branch_info = described_class.new(
        refname: 'remotes/origin/main', target_oid: 'abc123', current: false, worktree_path: nil,
        symref: nil, upstream: nil
      )
      expect(branch_info.to_s).to eq('remotes/origin/main')
    end
  end

  describe 'immutability' do
    it 'is frozen' do
      branch_info = described_class.new(
        refname: 'main', target_oid: 'abc123', current: true, worktree_path: nil,
        symref: nil, upstream: nil
      )
      expect(branch_info).to be_frozen
    end
  end

  describe 'equality' do
    it 'is equal to another BranchInfo with same attributes' do
      info1 = described_class.new(
        refname: 'main', target_oid: 'abc123', current: true, worktree_path: nil,
        symref: nil, upstream: nil
      )
      info2 = described_class.new(
        refname: 'main', target_oid: 'abc123', current: true, worktree_path: nil,
        symref: nil, upstream: nil
      )
      expect(info1).to eq(info2)
    end

    it 'is not equal when refname differs' do
      info1 = described_class.new(
        refname: 'main', target_oid: 'abc123', current: true, worktree_path: nil,
        symref: nil, upstream: nil
      )
      info2 = described_class.new(
        refname: 'develop', target_oid: 'abc123', current: true, worktree_path: nil,
        symref: nil, upstream: nil
      )
      expect(info1).not_to eq(info2)
    end

    it 'is not equal when current differs' do
      info1 = described_class.new(
        refname: 'main', target_oid: 'abc123', current: true, worktree_path: nil,
        symref: nil, upstream: nil
      )
      info2 = described_class.new(
        refname: 'main', target_oid: 'abc123', current: false, worktree_path: nil,
        symref: nil, upstream: nil
      )
      expect(info1).not_to eq(info2)
    end

    it 'is equal when explicit remote_name matches the fallback remote_name' do
      info1 = described_class.new(
        refname: 'refs/remotes/origin/main', target_oid: 'abc123', current: false, worktree_path: nil,
        symref: nil, upstream: nil
      )
      info2 = described_class.new(
        refname: 'refs/remotes/origin/main', target_oid: 'abc123', current: false, worktree_path: nil,
        symref: nil, upstream: nil, remote_name: 'origin'
      )

      expect(info1).to eq(info2)
    end
  end

  describe 'pattern matching' do
    it 'supports pattern matching on attributes' do
      branch_info = described_class.new(
        refname: 'main', target_oid: 'abc123', current: true, worktree_path: nil,
        symref: nil, upstream: nil
      )

      result = case branch_info
               in { refname: 'main', current: true }
                 :matched
               else
                 :not_matched
               end

      expect(result).to eq(:matched)
    end
  end

  describe 'upstream tracking' do
    context 'local branch tracking a remote-tracking branch' do
      subject(:branch_info) do
        described_class.new(
          refname: 'refs/heads/main',
          target_oid: 'abc123def456789012345678901234567890abcd',
          current: true,
          worktree_path: nil,
          symref: nil,
          upstream: 'refs/remotes/origin/main'
        )
      end

      it 'has an upstream' do
        expect(branch_info.upstream).not_to be_nil
      end

      it 'upstream is the raw upstream refname String' do
        expect(branch_info.upstream).to be_a(String)
      end

      it 'upstream equals the raw upstream refname' do
        expect(branch_info.upstream).to eq('refs/remotes/origin/main')
      end
    end

    context 'local branch tracking another local branch' do
      subject(:branch_info) do
        described_class.new(
          refname: 'refs/heads/feature',
          target_oid: 'def456789012345678901234567890abcdef12',
          current: false,
          worktree_path: nil,
          symref: nil,
          upstream: 'refs/heads/main'
        )
      end

      it 'upstream is the raw upstream refname String' do
        expect(branch_info.upstream).to eq('refs/heads/main')
      end
    end

    context 'branch with no upstream' do
      subject(:branch_info) do
        described_class.new(
          refname: 'orphan-branch',
          target_oid: 'ghi789012345678901234567890abcdef123456',
          current: false,
          worktree_path: nil,
          symref: nil,
          upstream: nil
        )
      end

      it 'has nil upstream' do
        expect(branch_info.upstream).to be_nil
      end
    end
  end

  describe 'target_oid scenarios' do
    context 'when target_oid is present' do
      subject(:branch_info) do
        described_class.new(
          refname: 'main',
          target_oid: 'abc123def456789012345678901234567890abcd',
          current: true,
          worktree_path: nil,
          symref: nil,
          upstream: nil
        )
      end

      it 'returns the commit SHA' do
        expect(branch_info.target_oid).to eq('abc123def456789012345678901234567890abcd')
      end
    end

    context 'when target_oid is nil (e.g., unborn branch)' do
      subject(:branch_info) do
        described_class.new(
          refname: 'unborn',
          target_oid: nil,
          current: false,
          worktree_path: nil,
          symref: nil,
          upstream: nil
        )
      end

      it 'returns nil' do
        expect(branch_info.target_oid).to be_nil
      end
    end
  end
end
