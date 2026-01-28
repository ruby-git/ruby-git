# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::BranchInfo do
  describe 'attributes' do
    subject(:branch_info) do
      described_class.new(
        refname: 'main',
        target_oid: 'abc123def456789012345678901234567890abcd',
        current: true,
        worktree: false,
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

    it 'exposes worktree' do
      expect(branch_info.worktree).to be false
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
  end

  describe '#current?' do
    it 'returns true when current is true' do
      branch_info = described_class.new(
        refname: 'main', target_oid: 'abc123', current: true, worktree: false, symref: nil, upstream: nil
      )
      expect(branch_info.current?).to be true
    end

    it 'returns false when current is false' do
      branch_info = described_class.new(
        refname: 'main', target_oid: 'abc123', current: false, worktree: false, symref: nil, upstream: nil
      )
      expect(branch_info.current?).to be false
    end
  end

  describe '#worktree?' do
    it 'returns true when worktree is true' do
      branch_info = described_class.new(
        refname: 'feature', target_oid: 'abc123', current: false, worktree: true, symref: nil, upstream: nil
      )
      expect(branch_info.worktree?).to be true
    end

    it 'returns false when worktree is false' do
      branch_info = described_class.new(
        refname: 'feature', target_oid: 'abc123', current: false, worktree: false, symref: nil, upstream: nil
      )
      expect(branch_info.worktree?).to be false
    end
  end

  describe '#symref?' do
    it 'returns true when symref is present' do
      branch_info = described_class.new(
        refname: 'HEAD', target_oid: 'abc123', current: false, worktree: false,
        symref: 'refs/heads/main', upstream: nil
      )
      expect(branch_info.symref?).to be true
    end

    it 'returns false when symref is nil' do
      branch_info = described_class.new(
        refname: 'main', target_oid: 'abc123', current: false, worktree: false, symref: nil, upstream: nil
      )
      expect(branch_info.symref?).to be false
    end
  end

  describe '#remote?' do
    context 'with local branch' do
      it 'returns false for simple branch name' do
        branch_info = described_class.new(
          refname: 'main', target_oid: 'abc123', current: false, worktree: false, symref: nil, upstream: nil
        )
        expect(branch_info.remote?).to be false
      end

      it 'returns false for branch with slashes' do
        branch_info = described_class.new(
          refname: 'feature/my-feature', target_oid: 'abc123', current: false, worktree: false,
          symref: nil, upstream: nil
        )
        expect(branch_info.remote?).to be false
      end
    end

    context 'with remote-tracking branch' do
      it 'returns true for remotes/origin/main' do
        branch_info = described_class.new(
          refname: 'remotes/origin/main', target_oid: 'abc123', current: false, worktree: false,
          symref: nil, upstream: nil
        )
        expect(branch_info.remote?).to be true
      end

      it 'returns true for refs/remotes/origin/main' do
        branch_info = described_class.new(
          refname: 'refs/remotes/origin/main', target_oid: 'abc123', current: false, worktree: false,
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
          refname: 'main', target_oid: 'abc123', current: false, worktree: false, symref: nil, upstream: nil
        )
        expect(branch_info.remote_name).to be_nil
      end

      it 'returns nil for branch with slashes' do
        branch_info = described_class.new(
          refname: 'feature/my-feature', target_oid: 'abc123', current: false, worktree: false,
          symref: nil, upstream: nil
        )
        expect(branch_info.remote_name).to be_nil
      end
    end

    context 'with remote-tracking branch' do
      it 'extracts remote name from remotes/origin/main' do
        branch_info = described_class.new(
          refname: 'remotes/origin/main', target_oid: 'abc123', current: false, worktree: false,
          symref: nil, upstream: nil
        )
        expect(branch_info.remote_name).to eq('origin')
      end

      it 'extracts remote name from refs/remotes/origin/main' do
        branch_info = described_class.new(
          refname: 'refs/remotes/origin/main', target_oid: 'abc123', current: false, worktree: false,
          symref: nil, upstream: nil
        )
        expect(branch_info.remote_name).to eq('origin')
      end

      it 'extracts remote name from remotes/upstream/feature' do
        branch_info = described_class.new(
          refname: 'remotes/upstream/feature', target_oid: 'abc123', current: false, worktree: false,
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
          refname: 'main', target_oid: 'abc123', current: false, worktree: false, symref: nil, upstream: nil
        )
        expect(branch_info.short_name).to eq('main')
      end

      it 'returns the full name for branch with slashes' do
        branch_info = described_class.new(
          refname: 'feature/my-feature', target_oid: 'abc123', current: false, worktree: false,
          symref: nil, upstream: nil
        )
        expect(branch_info.short_name).to eq('feature/my-feature')
      end

      it 'returns the full name for deeply nested branch' do
        branch_info = described_class.new(
          refname: 'feature/team/project/task', target_oid: 'abc123', current: false, worktree: false,
          symref: nil, upstream: nil
        )
        expect(branch_info.short_name).to eq('feature/team/project/task')
      end
    end

    context 'with remote-tracking branch' do
      it 'extracts branch name from remotes/origin/main' do
        branch_info = described_class.new(
          refname: 'remotes/origin/main', target_oid: 'abc123', current: false, worktree: false,
          symref: nil, upstream: nil
        )
        expect(branch_info.short_name).to eq('main')
      end

      it 'extracts branch name from refs/remotes/origin/main' do
        branch_info = described_class.new(
          refname: 'refs/remotes/origin/main', target_oid: 'abc123', current: false, worktree: false,
          symref: nil, upstream: nil
        )
        expect(branch_info.short_name).to eq('main')
      end

      it 'preserves slashes in remote branch name' do
        branch_info = described_class.new(
          refname: 'remotes/origin/feature/my-feature', target_oid: 'abc123', current: false,
          worktree: false, symref: nil, upstream: nil
        )
        expect(branch_info.short_name).to eq('feature/my-feature')
      end
    end
  end

  describe '#to_s' do
    it 'returns the refname' do
      branch_info = described_class.new(
        refname: 'main', target_oid: 'abc123', current: true, worktree: false, symref: nil, upstream: nil
      )
      expect(branch_info.to_s).to eq('main')
    end

    it 'returns full refname for remote branches' do
      branch_info = described_class.new(
        refname: 'remotes/origin/main', target_oid: 'abc123', current: false, worktree: false,
        symref: nil, upstream: nil
      )
      expect(branch_info.to_s).to eq('remotes/origin/main')
    end
  end

  describe 'immutability' do
    it 'is frozen' do
      branch_info = described_class.new(
        refname: 'main', target_oid: 'abc123', current: true, worktree: false, symref: nil, upstream: nil
      )
      expect(branch_info).to be_frozen
    end
  end

  describe 'equality' do
    it 'is equal to another BranchInfo with same attributes' do
      info1 = described_class.new(
        refname: 'main', target_oid: 'abc123', current: true, worktree: false, symref: nil, upstream: nil
      )
      info2 = described_class.new(
        refname: 'main', target_oid: 'abc123', current: true, worktree: false, symref: nil, upstream: nil
      )
      expect(info1).to eq(info2)
    end

    it 'is not equal when refname differs' do
      info1 = described_class.new(
        refname: 'main', target_oid: 'abc123', current: true, worktree: false, symref: nil, upstream: nil
      )
      info2 = described_class.new(
        refname: 'develop', target_oid: 'abc123', current: true, worktree: false, symref: nil, upstream: nil
      )
      expect(info1).not_to eq(info2)
    end

    it 'is not equal when current differs' do
      info1 = described_class.new(
        refname: 'main', target_oid: 'abc123', current: true, worktree: false, symref: nil, upstream: nil
      )
      info2 = described_class.new(
        refname: 'main', target_oid: 'abc123', current: false, worktree: false, symref: nil, upstream: nil
      )
      expect(info1).not_to eq(info2)
    end
  end

  describe 'pattern matching' do
    it 'supports pattern matching on attributes' do
      branch_info = described_class.new(
        refname: 'main', target_oid: 'abc123', current: true, worktree: false, symref: nil, upstream: nil
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
      let(:upstream_info) do
        described_class.new(
          refname: 'remotes/origin/main',
          target_oid: 'abc123def456789012345678901234567890abcd',
          current: false,
          worktree: false,
          symref: nil,
          upstream: nil
        )
      end

      subject(:branch_info) do
        described_class.new(
          refname: 'main',
          target_oid: 'abc123def456789012345678901234567890abcd',
          current: true,
          worktree: false,
          symref: nil,
          upstream: upstream_info
        )
      end

      it 'has an upstream' do
        expect(branch_info.upstream).not_to be_nil
      end

      it 'upstream is a BranchInfo' do
        expect(branch_info.upstream).to be_a(Git::BranchInfo)
      end

      it 'upstream has no upstream of its own' do
        expect(branch_info.upstream.upstream).to be_nil
      end

      it 'allows accessing upstream properties' do
        expect(branch_info.upstream.remote_name).to eq('origin')
        expect(branch_info.upstream.short_name).to eq('main')
      end
    end

    context 'local branch tracking another local branch' do
      let(:upstream_local) do
        described_class.new(
          refname: 'main',
          target_oid: 'abc123def456789012345678901234567890abcd',
          current: false,
          worktree: false,
          symref: nil,
          upstream: nil
        )
      end

      subject(:branch_info) do
        described_class.new(
          refname: 'feature',
          target_oid: 'def456789012345678901234567890abcdef12',
          current: false,
          worktree: false,
          symref: nil,
          upstream: upstream_local
        )
      end

      it 'has a local branch as upstream' do
        expect(branch_info.upstream.remote?).to be false
      end

      it 'upstream refname is the local branch name' do
        expect(branch_info.upstream.refname).to eq('main')
      end
    end

    context 'branch with no upstream' do
      subject(:branch_info) do
        described_class.new(
          refname: 'orphan-branch',
          target_oid: 'ghi789012345678901234567890abcdef123456',
          current: false,
          worktree: false,
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
          worktree: false,
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
          worktree: false,
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
