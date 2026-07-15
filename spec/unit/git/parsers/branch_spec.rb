# frozen_string_literal: true

require 'spec_helper'
require 'git/parsers/branch'

RSpec.describe Git::Parsers::Branch do
  describe '.parse_list' do
    it 'parses a single local branch' do
      stdout = "refs/heads/main\0abc123def456789012345678901234567890abcdef\0*\0\0\0\n"
      result = described_class.parse_list(stdout)

      expect(result.size).to eq(1)
      expect(result[0].refname).to eq('refs/heads/main')
      expect(result[0].target_oid).to eq('abc123def456789012345678901234567890abcdef')
      expect(result[0].current?).to be true
      expect(result[0].other_worktree?).to be false
    end

    it 'parses multiple branches' do
      stdout = <<~OUTPUT
        refs/heads/main\0abc123\0*\0\0\0refs/remotes/origin/main
        refs/heads/feature\0def456\0\0\0\0
      OUTPUT
      result = described_class.parse_list(stdout)

      expect(result.size).to eq(2)
      expect(result[0].refname).to eq('refs/heads/main')
      expect(result[0].current?).to be true
      expect(result[0].upstream).to eq('refs/remotes/origin/main')
      expect(result[1].refname).to eq('refs/heads/feature')
      expect(result[1].current?).to be false
    end

    it 'parses remote-tracking branches' do
      stdout = "refs/remotes/origin/main\0abc123\0\0\0\0\n"
      result = described_class.parse_list(stdout)

      expect(result.size).to eq(1)
      expect(result[0].refname).to eq('refs/remotes/origin/main')
      expect(result[0].remote?).to be true
      expect(result[0].remote_name).to eq('origin')
    end

    it 'skips detached HEAD entries' do
      stdout = <<~OUTPUT
        (HEAD detached at abc123)\0abc123\0\0\0\0
        refs/heads/main\0def456\0\0\0\0
      OUTPUT
      result = described_class.parse_list(stdout)

      expect(result.size).to eq(1)
      expect(result[0].refname).to eq('refs/heads/main')
    end

    it 'skips non-branch entries' do
      stdout = <<~OUTPUT
        (not a branch)\0\0\0\0\0
        refs/heads/main\0abc123\0\0\0\0
      OUTPUT
      result = described_class.parse_list(stdout)

      expect(result.size).to eq(1)
      expect(result[0].refname).to eq('refs/heads/main')
    end

    it 'returns empty array for empty input' do
      result = described_class.parse_list('')

      expect(result).to be_empty
    end

    it 'parses branch checked out in another worktree' do
      stdout = "refs/heads/feature\0abc123\0\0/path/to/worktree\0\0\n"
      result = described_class.parse_list(stdout)

      expect(result[0].other_worktree?).to be true
      expect(result[0].worktree_path).to eq('/path/to/worktree')
    end

    it 'does not mark current branch as worktree even with worktree path' do
      stdout = "refs/heads/main\0abc123\0*\0/path/to/main\0\0\n"
      result = described_class.parse_list(stdout)

      expect(result[0].current?).to be true
      expect(result[0].other_worktree?).to be false
    end

    it 'parses symbolic reference' do
      stdout = "refs/heads/HEAD\0abc123\0\0\0refs/heads/main\0\n"
      result = described_class.parse_list(stdout)

      expect(result[0].symref?).to be true
      expect(result[0].symref).to eq('refs/heads/main')
    end
  end

  describe '.parse_branch_line' do
    it 'returns nil for detached HEAD' do
      line = "(HEAD detached at abc123)\0abc123\0\0\0\0"
      result = described_class.parse_branch_line(line)

      expect(result).to be_nil
    end

    it 'returns nil for (not a branch) entries' do
      line = "(not a branch)\0\0\0\0\0"
      result = described_class.parse_branch_line(line)

      expect(result).to be_nil
    end

    it 'parses a valid branch line' do
      line = "refs/heads/main\0abc123\0*\0\0\0"
      result = described_class.parse_branch_line(line)

      expect(result).to be_a(Git::BranchInfo)
      expect(result.refname).to eq('refs/heads/main')
    end
  end

  describe '.build_branch_info' do
    it 'builds a BranchInfo with all fields' do
      fields = ['refs/heads/main', 'abc123', '*', '', '', 'refs/remotes/origin/main']
      result = described_class.build_branch_info(fields)

      expect(result.refname).to eq('refs/heads/main')
      expect(result.target_oid).to eq('abc123')
      expect(result.current?).to be true
      expect(result.upstream).to eq('refs/remotes/origin/main')
    end

    it 'handles nil/empty optional fields' do
      fields = ['refs/heads/feature', '', '', '', '', '']
      result = described_class.build_branch_info(fields)

      expect(result.refname).to eq('refs/heads/feature')
      expect(result.target_oid).to be_nil
      expect(result.current?).to be false
      expect(result.symref).to be_nil
      expect(result.upstream).to be_nil
    end
  end

  describe '.non_branch_entry?' do
    it 'returns true for detached HEAD' do
      expect(described_class.non_branch_entry?('(HEAD detached at abc123)')).to be true
    end

    it 'returns true for (not a branch)' do
      expect(described_class.non_branch_entry?('(not a branch)')).to be true
    end

    it 'returns false for regular branch names' do
      expect(described_class.non_branch_entry?('main')).to be false
      expect(described_class.non_branch_entry?('feature/test')).to be false
      expect(described_class.non_branch_entry?('refs/heads/main')).to be false
    end
  end

  describe '.build_upstream_info' do
    it 'returns the raw upstream refname string for a valid upstream ref' do
      expect(described_class.build_upstream_info('refs/remotes/origin/main')).to eq('refs/remotes/origin/main')
    end

    it 'returns nil for empty upstream ref' do
      expect(described_class.build_upstream_info('')).to be_nil
    end

    it 'returns nil for nil upstream ref' do
      expect(described_class.build_upstream_info(nil)).to be_nil
    end
  end

  describe '.presence' do
    it 'returns the value when non-empty' do
      expect(described_class.presence('abc123')).to eq('abc123')
    end

    it 'returns nil for empty string' do
      expect(described_class.presence('')).to be_nil
    end

    it 'returns nil for nil' do
      expect(described_class.presence(nil)).to be_nil
    end
  end

  describe '.parse_deleted_branches' do
    it 'parses single deleted branch' do
      stdout = "Deleted branch feature (was abc123).\n"
      result = described_class.parse_deleted_branches(stdout)

      expect(result).to eq(['feature'])
    end

    it 'parses multiple deleted branches' do
      stdout = <<~OUTPUT
        Deleted branch feature-1 (was abc123).
        Deleted branch feature-2 (was def456).
      OUTPUT
      result = described_class.parse_deleted_branches(stdout)

      expect(result).to eq(%w[feature-1 feature-2])
    end

    it 'parses deleted remote-tracking branch' do
      stdout = "Deleted remote-tracking branch origin/feature (was abc123).\n"
      result = described_class.parse_deleted_branches(stdout)

      expect(result).to eq(['origin/feature'])
    end

    it 'returns empty array for empty output' do
      result = described_class.parse_deleted_branches('')

      expect(result).to eq([])
    end

    it 'handles branch names with special characters' do
      stdout = "Deleted branch feature/my-branch (was abc123).\n"
      result = described_class.parse_deleted_branches(stdout)

      expect(result).to eq(['feature/my-branch'])
    end

    it 'handles branch names with spaces' do
      stdout = "Deleted branch my branch name (was abc1234).\n"
      result = described_class.parse_deleted_branches(stdout)

      expect(result).to eq(['my branch name'])
    end

    it 'handles multiple branches with spaces and special characters' do
      stdout = <<~OUTPUT
        Deleted branch feature/my-branch (was abc1234).
        Deleted branch test branch 123 (was def5678).
      OUTPUT
      result = described_class.parse_deleted_branches(stdout)

      expect(result).to eq(['feature/my-branch', 'test branch 123'])
    end
  end

  describe '.parse_error_messages' do
    it 'parses single error message' do
      stderr = "error: branch 'missing' not found.\n"
      result = described_class.parse_error_messages(stderr)

      expect(result).to eq({ 'missing' => "error: branch 'missing' not found." })
    end

    it 'parses multiple error messages' do
      stderr = <<~OUTPUT
        error: branch 'missing1' not found.
        error: branch 'missing2' not found.
      OUTPUT
      result = described_class.parse_error_messages(stderr)

      expect(result).to eq({
                             'missing1' => "error: branch 'missing1' not found.",
                             'missing2' => "error: branch 'missing2' not found."
                           })
    end

    it 'returns empty hash for empty stderr' do
      result = described_class.parse_error_messages('')

      expect(result).to eq({})
    end

    it 'ignores non-matching lines' do
      stderr = <<~OUTPUT
        Some other output
        error: branch 'missing' not found.
        Another line
      OUTPUT
      result = described_class.parse_error_messages(stderr)

      expect(result).to eq({ 'missing' => "error: branch 'missing' not found." })
    end
  end

  describe '.build_delete_result' do
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

    it 'builds result with deleted branches' do
      requested_names = ['feature']
      existing_branches = { 'feature' => branch_info }
      deleted_names = ['feature']
      error_map = {}

      result = described_class.build_delete_result(
        requested_names, existing_branches, deleted_names, error_map
      )

      expect(result).to be_a(Git::BranchDeleteResult)
      expect(result.success?).to be true
      expect(result.deleted.size).to eq(1)
      expect(result.deleted[0].refname).to eq('feature')
      expect(result.not_deleted).to be_empty
    end

    it 'builds result with failures' do
      requested_names = %w[feature missing]
      existing_branches = { 'feature' => branch_info }
      deleted_names = ['feature']
      error_map = { 'missing' => "error: branch 'missing' not found." }

      result = described_class.build_delete_result(
        requested_names, existing_branches, deleted_names, error_map
      )

      expect(result.success?).to be false
      expect(result.deleted.size).to eq(1)
      expect(result.not_deleted.size).to eq(1)
      expect(result.not_deleted[0].name).to eq('missing')
      expect(result.not_deleted[0].error_message).to eq("error: branch 'missing' not found.")
    end

    it 'uses default error message when not in error_map' do
      requested_names = ['missing']
      existing_branches = {}
      deleted_names = []
      error_map = {}

      result = described_class.build_delete_result(
        requested_names, existing_branches, deleted_names, error_map
      )

      expect(result.not_deleted[0].error_message).to eq("branch 'missing' could not be deleted")
    end
  end
end
