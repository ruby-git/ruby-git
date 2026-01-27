# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::BranchInfo do
  describe 'attributes' do
    subject(:branch_info) do
      described_class.new(refname: 'main', current: true, worktree: false, symref: nil)
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
  end

  describe '#current?' do
    it 'returns true when current is true' do
      branch_info = described_class.new(refname: 'main', current: true, worktree: false, symref: nil)
      expect(branch_info.current?).to be true
    end

    it 'returns false when current is false' do
      branch_info = described_class.new(refname: 'main', current: false, worktree: false, symref: nil)
      expect(branch_info.current?).to be false
    end
  end

  describe '#worktree?' do
    it 'returns true when worktree is true' do
      branch_info = described_class.new(refname: 'feature', current: false, worktree: true, symref: nil)
      expect(branch_info.worktree?).to be true
    end

    it 'returns false when worktree is false' do
      branch_info = described_class.new(refname: 'feature', current: false, worktree: false, symref: nil)
      expect(branch_info.worktree?).to be false
    end
  end

  describe '#symref?' do
    it 'returns true when symref is present' do
      branch_info = described_class.new(refname: 'HEAD', current: false, worktree: false, symref: 'refs/heads/main')
      expect(branch_info.symref?).to be true
    end

    it 'returns false when symref is nil' do
      branch_info = described_class.new(refname: 'main', current: false, worktree: false, symref: nil)
      expect(branch_info.symref?).to be false
    end
  end

  describe '#remote?' do
    context 'with local branch' do
      it 'returns false for simple branch name' do
        branch_info = described_class.new(refname: 'main', current: false, worktree: false, symref: nil)
        expect(branch_info.remote?).to be false
      end

      it 'returns false for branch with slashes' do
        branch_info = described_class.new(refname: 'feature/my-feature', current: false, worktree: false, symref: nil)
        expect(branch_info.remote?).to be false
      end
    end

    context 'with remote-tracking branch' do
      it 'returns true for remotes/origin/main' do
        branch_info = described_class.new(refname: 'remotes/origin/main', current: false, worktree: false, symref: nil)
        expect(branch_info.remote?).to be true
      end

      it 'returns true for refs/remotes/origin/main' do
        branch_info = described_class.new(
          refname: 'refs/remotes/origin/main', current: false, worktree: false, symref: nil
        )
        expect(branch_info.remote?).to be true
      end
    end
  end

  describe '#remote_name' do
    context 'with local branch' do
      it 'returns nil for simple branch name' do
        branch_info = described_class.new(refname: 'main', current: false, worktree: false, symref: nil)
        expect(branch_info.remote_name).to be_nil
      end

      it 'returns nil for branch with slashes' do
        branch_info = described_class.new(refname: 'feature/my-feature', current: false, worktree: false, symref: nil)
        expect(branch_info.remote_name).to be_nil
      end
    end

    context 'with remote-tracking branch' do
      it 'extracts remote name from remotes/origin/main' do
        branch_info = described_class.new(refname: 'remotes/origin/main', current: false, worktree: false, symref: nil)
        expect(branch_info.remote_name).to eq('origin')
      end

      it 'extracts remote name from refs/remotes/origin/main' do
        branch_info = described_class.new(
          refname: 'refs/remotes/origin/main', current: false, worktree: false, symref: nil
        )
        expect(branch_info.remote_name).to eq('origin')
      end

      it 'extracts remote name from remotes/upstream/feature' do
        branch_info = described_class.new(
          refname: 'remotes/upstream/feature', current: false, worktree: false, symref: nil
        )
        expect(branch_info.remote_name).to eq('upstream')
      end
    end
  end

  describe '#short_name' do
    context 'with local branch' do
      it 'returns the branch name for simple branch' do
        branch_info = described_class.new(refname: 'main', current: false, worktree: false, symref: nil)
        expect(branch_info.short_name).to eq('main')
      end

      it 'returns the full name for branch with slashes' do
        branch_info = described_class.new(refname: 'feature/my-feature', current: false, worktree: false, symref: nil)
        expect(branch_info.short_name).to eq('feature/my-feature')
      end

      it 'returns the full name for deeply nested branch' do
        branch_info = described_class.new(
          refname: 'feature/team/project/task', current: false, worktree: false, symref: nil
        )
        expect(branch_info.short_name).to eq('feature/team/project/task')
      end
    end

    context 'with remote-tracking branch' do
      it 'extracts branch name from remotes/origin/main' do
        branch_info = described_class.new(refname: 'remotes/origin/main', current: false, worktree: false, symref: nil)
        expect(branch_info.short_name).to eq('main')
      end

      it 'extracts branch name from refs/remotes/origin/main' do
        branch_info = described_class.new(
          refname: 'refs/remotes/origin/main', current: false, worktree: false, symref: nil
        )
        expect(branch_info.short_name).to eq('main')
      end

      it 'preserves slashes in remote branch name' do
        branch_info = described_class.new(
          refname: 'remotes/origin/feature/my-feature', current: false, worktree: false, symref: nil
        )
        expect(branch_info.short_name).to eq('feature/my-feature')
      end
    end
  end

  describe '#to_s' do
    it 'returns the refname' do
      branch_info = described_class.new(refname: 'main', current: true, worktree: false, symref: nil)
      expect(branch_info.to_s).to eq('main')
    end

    it 'returns full refname for remote branches' do
      branch_info = described_class.new(refname: 'remotes/origin/main', current: false, worktree: false, symref: nil)
      expect(branch_info.to_s).to eq('remotes/origin/main')
    end
  end

  describe 'immutability' do
    it 'is frozen' do
      branch_info = described_class.new(refname: 'main', current: true, worktree: false, symref: nil)
      expect(branch_info).to be_frozen
    end
  end

  describe 'equality' do
    it 'is equal to another BranchInfo with same attributes' do
      info1 = described_class.new(refname: 'main', current: true, worktree: false, symref: nil)
      info2 = described_class.new(refname: 'main', current: true, worktree: false, symref: nil)
      expect(info1).to eq(info2)
    end

    it 'is not equal when refname differs' do
      info1 = described_class.new(refname: 'main', current: true, worktree: false, symref: nil)
      info2 = described_class.new(refname: 'develop', current: true, worktree: false, symref: nil)
      expect(info1).not_to eq(info2)
    end

    it 'is not equal when current differs' do
      info1 = described_class.new(refname: 'main', current: true, worktree: false, symref: nil)
      info2 = described_class.new(refname: 'main', current: false, worktree: false, symref: nil)
      expect(info1).not_to eq(info2)
    end
  end

  describe 'pattern matching' do
    it 'supports pattern matching on attributes' do
      branch_info = described_class.new(refname: 'main', current: true, worktree: false, symref: nil)

      result = case branch_info
               in { refname: 'main', current: true }
                 :matched
               else
                 :not_matched
               end

      expect(result).to eq(:matched)
    end
  end
end
