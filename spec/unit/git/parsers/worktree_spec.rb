# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Parsers::Worktree do
  # Build a Git::WorktreeInfo with every flag off unless overridden
  def worktree_info(path:, **overrides)
    Git::WorktreeInfo.new(
      path: path, head: nil, branch: nil, bare: false, detached: false,
      locked: false, lock_reason: nil, prunable: false, prune_reason: nil, **overrides
    )
  end

  let(:sha) { 'f3e2c1ffb860086504eeb27b77a1d0028b68fd8f' }

  describe '.parse_list' do
    subject(:result) { described_class.parse_list(stdout) }

    context 'when the output is empty' do
      let(:stdout) { '' }

      it 'returns an empty array' do
        expect(result).to eq([])
      end
    end

    context 'with a main worktree on a branch' do
      let(:stdout) do
        "worktree /tmp/wt/main\n" \
          "HEAD #{sha}\n" \
          "branch refs/heads/main\n"
      end

      it 'returns one Git::WorktreeInfo with the path, head, and branch' do
        expect(result).to eq(
          [worktree_info(path: '/tmp/wt/main', head: sha, branch: 'refs/heads/main')]
        )
      end
    end

    context 'with a bare main worktree' do
      let(:stdout) do
        "worktree /tmp/wt/repo.git\n" \
          "bare\n"
      end

      it 'returns a bare Git::WorktreeInfo with a nil head and branch' do
        expect(result).to eq([worktree_info(path: '/tmp/wt/repo.git', bare: true)])
      end
    end

    context 'with a detached worktree' do
      let(:stdout) do
        "worktree /tmp/wt/det\n" \
          "HEAD #{sha}\n" \
          "detached\n"
      end

      it 'returns a detached Git::WorktreeInfo with a nil branch' do
        expect(result).to eq([worktree_info(path: '/tmp/wt/det', head: sha, detached: true)])
      end
    end

    context 'with a locked worktree without a reason' do
      let(:stdout) do
        "worktree /tmp/wt/det\n" \
          "HEAD #{sha}\n" \
          "detached\n" \
          "locked\n"
      end

      it 'returns a locked Git::WorktreeInfo with a nil lock_reason' do
        expect(result).to eq(
          [worktree_info(path: '/tmp/wt/det', head: sha, detached: true, locked: true)]
        )
      end
    end

    context 'with a locked worktree with a reason' do
      let(:stdout) do
        "worktree /tmp/wt/linked\n" \
          "HEAD #{sha}\n" \
          "branch refs/heads/linked\n" \
          "locked on purpose\n"
      end

      it 'returns a locked Git::WorktreeInfo with the lock_reason' do
        expect(result).to eq(
          [
            worktree_info(
              path: '/tmp/wt/linked', head: sha, branch: 'refs/heads/linked',
              locked: true, lock_reason: 'on purpose'
            )
          ]
        )
      end
    end

    context 'with a C-quoted lock reason' do
      let(:stdout) do
        "worktree /tmp/wt/linked\n" \
          "HEAD #{sha}\n" \
          "branch refs/heads/linked\n" \
          "locked \"line1\\nline2 \\303\\251\"\n"
      end

      it 'returns the lock_reason as git prints it, without unquoting' do
        expect(result.first.lock_reason).to eq('"line1\\nline2 \\303\\251"')
      end
    end

    context 'with a prunable worktree' do
      let(:stdout) do
        "worktree /tmp/wt/gone\n" \
          "HEAD #{sha}\n" \
          "branch refs/heads/gone\n" \
          "prunable gitdir file points to non-existent location\n"
      end

      it 'returns a prunable Git::WorktreeInfo with the prune_reason' do
        expect(result).to eq(
          [
            worktree_info(
              path: '/tmp/wt/gone', head: sha, branch: 'refs/heads/gone',
              prunable: true, prune_reason: 'gitdir file points to non-existent location'
            )
          ]
        )
      end
    end

    context 'with multiple worktrees' do
      let(:stdout) do
        "worktree /tmp/wt/main\n" \
          "HEAD #{sha}\n" \
          "branch refs/heads/main\n" \
          "\n" \
          "worktree /tmp/wt/det\n" \
          "HEAD #{sha}\n" \
          "detached\n" \
          "locked\n" \
          "\n" \
          "worktree /tmp/wt/gone\n" \
          "HEAD #{sha}\n" \
          "branch refs/heads/gone\n" \
          "prunable gitdir file points to non-existent location\n" \
          "\n" \
          "worktree /tmp/wt/linked\n" \
          "HEAD #{sha}\n" \
          "branch refs/heads/linked\n" \
          "locked on purpose\n" \
          "\n"
      end

      it 'returns one Git::WorktreeInfo per record in the order git printed them' do
        expect(result).to eq(
          [
            worktree_info(path: '/tmp/wt/main', head: sha, branch: 'refs/heads/main'),
            worktree_info(path: '/tmp/wt/det', head: sha, detached: true, locked: true),
            worktree_info(
              path: '/tmp/wt/gone', head: sha, branch: 'refs/heads/gone',
              prunable: true, prune_reason: 'gitdir file points to non-existent location'
            ),
            worktree_info(
              path: '/tmp/wt/linked', head: sha, branch: 'refs/heads/linked',
              locked: true, lock_reason: 'on purpose'
            )
          ]
        )
      end
    end

    context 'when a worktree path contains spaces' do
      let(:stdout) do
        "worktree /tmp/worktree with spaces\n" \
          "HEAD #{sha}\n" \
          "detached\n"
      end

      it 'preserves the full path' do
        expect(result.first.path).to eq('/tmp/worktree with spaces')
      end
    end

    context 'when the output uses CRLF line endings' do
      let(:stdout) do
        "worktree /tmp/wt/main\r\n" \
          "HEAD #{sha}\r\n" \
          "branch refs/heads/main\r\n" \
          "\r\n" \
          "worktree /tmp/wt/det\r\n" \
          "HEAD #{sha}\r\n" \
          "detached\r\n"
      end

      it 'parses records without carriage returns in the values' do
        expect(result).to eq(
          [
            worktree_info(path: '/tmp/wt/main', head: sha, branch: 'refs/heads/main'),
            worktree_info(path: '/tmp/wt/det', head: sha, detached: true)
          ]
        )
      end
    end

    context 'when a record does not start with a worktree line' do
      let(:stdout) do
        "HEAD #{sha}\n" \
          "branch refs/heads/main\n"
      end

      it 'raises Git::UnexpectedResultError with the full output in the message' do
        expect { result }.to raise_error(Git::UnexpectedResultError, /git worktree list --porcelain/) do |error|
          expect(error.message).to include("HEAD #{sha}")
          expect(error.message).to include('branch refs/heads/main')
        end
      end
    end

    context 'when a record contains an unrecognized key' do
      let(:stdout) do
        "worktree /tmp/wt/main\n" \
          "HEAD #{sha}\n" \
          "unexpected value\n"
      end

      it 'raises Git::UnexpectedResultError naming the line and including the full output' do
        expect { result }.to raise_error(Git::UnexpectedResultError, /unexpected value/) do |error|
          expect(error.message).to include('worktree /tmp/wt/main')
        end
      end
    end
  end
end
