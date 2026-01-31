# frozen_string_literal: true

module Git
  module Commands
    # Commands for showing differences between commits, trees, and the working tree
    #
    # This module contains command classes for different diff output formats:
    # - {Diff::Numstat} - Line counts per file (machine-readable)
    # - {Diff::Raw} - File metadata with modes, SHAs, and status
    # - {Diff::Patch} - Full unified diff patches
    #
    # @see https://git-scm.com/docs/git-diff git-diff documentation
    #
    # Examples use {Diff::Numstat}, but the same patterns apply to all diff commands.
    # `ctx` is the execution context used to run git commands.
    #
    # @example Compare the index to the working tree
    #   # git diff [--] [<path>...]
    #   Numstat.new(ctx).call
    #   Numstat.new(ctx).call(pathspecs: ['lib/', '*.rb'])
    #
    # @example Compare two paths on the filesystem (outside git)
    #   # git diff --no-index [--] <path> <path>
    #   Numstat.new(ctx).call('/path/a', '/path/b', no_index: true)
    #
    # @example Compare the index to HEAD or the named commit
    #   # git diff --cached [<commit>] [--] [<path>...]
    #   Numstat.new(ctx).call(cached: true)
    #   Numstat.new(ctx).call('HEAD~3', cached: true, pathspecs: ['lib/'])
    #
    # @example Compare the working tree to the named commit
    #   # git diff <commit> [--] [<path>...]
    #   Numstat.new(ctx).call('HEAD~3')
    #   Numstat.new(ctx).call('abc123', pathspecs: ['lib/', '*.rb'])
    #
    # @example Compare two commits
    #   # git diff <commit> <commit> [--] [<path>...]
    #   # git diff <commit>..<commit> [--] [<path>...]
    #   # git diff <commit>...<commit> [--] [<path>...]
    #   Numstat.new(ctx).call('abc123', 'def456')
    #   Numstat.new(ctx).call('v1.0..v2.0')   # two-dot range syntax
    #   Numstat.new(ctx).call('main...feature')  # three-dot (merge-base) syntax
    #
    # @example Show changes introduced by a merge commit beyond the merged branches
    #   # git diff <merge-commit> <commit>...<commit> [--] [<path>...]
    #   Numstat.new(ctx).call('merge_commit', 'main...feature')
    #
    # @note Combined/merge diffs (e.g., `git diff --cc`, `git show <merge>`) are not
    #   currently supported. Combined diffs have a different format with multiple columns
    #   of +/- markers (one per parent) and require specialized parsing. Standard two-way
    #   diffs cover the primary use cases. Combined diff support may be added in a future
    #   version if there is demand.
    #
    module Diff
    end
  end
end
