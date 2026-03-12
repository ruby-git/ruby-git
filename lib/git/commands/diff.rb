# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git diff` command
    #
    # Compares commits, the index, and the working tree.
    #
    # @see https://git-scm.com/docs/git-diff git-diff documentation
    #
    # @see Git::Commands
    #
    # @api private
    #
    # @example Compare the index to the working tree (numstat output)
    #   # git diff --numstat --shortstat --src-prefix=a/ --dst-prefix=b/
    #   Git::Commands::Diff.new(ctx).call(numstat: true, shortstat: true, src_prefix: 'a/', dst_prefix: 'b/')
    #
    # @example Compare two paths on the filesystem (outside git)
    #   # git diff --patch --no-index -- <path> <path>
    #   Git::Commands::Diff.new(ctx).call(patch: true, no_index: true, path: ['/path/a', '/path/b'])
    #
    # @example Compare the index to HEAD (patch output)
    #   # git diff --patch --cached
    #   Git::Commands::Diff.new(ctx).call(patch: true, cached: true)
    #
    # @example Compare two commits (raw output)
    #   # git diff --raw --numstat --shortstat 'abc123' 'def456'
    #   Git::Commands::Diff.new(ctx).call('abc123', 'def456', raw: true, numstat: true, shortstat: true)
    #
    class Diff < Git::Commands::Base
      arguments do
        literal 'diff'

        flag_option :patch
        flag_option :numstat
        flag_option :raw
        flag_option :shortstat

        value_option :src_prefix, inline: true
        value_option :dst_prefix, inline: true

        flag_option %i[cached staged]
        flag_option :merge_base
        flag_option :no_index
        flag_or_value_option %i[find_renames M], inline: true
        flag_or_value_option %i[find_copies C], inline: true
        flag_option :find_copies_harder
        flag_or_value_option :dirstat, inline: true
        operand :commit, repeatable: true
        end_of_options
        value_option %i[path pathspecs], as_operand: true, repeatable: true
      end

      # git diff exit codes: 0 = no diff, 1 = diff found, 2+ = error
      allow_exit_status 0..1

      # @!method call(*, **)
      #
      #   @api public
      #
      #   @overload call(**options)
      #     Compare the index to the working tree
      #
      #     @example
      #       # git diff [--numstat] [--shortstat] [--src-prefix=a/] [--dst-prefix=b/]
      #       Diff.new(ctx).call(numstat: true, shortstat: true, src_prefix: 'a/', dst_prefix: 'b/')
      #
      #     @param options [Hash] command options
      #
      #     @return [Git::CommandLineResult] the result of calling `git diff`
      #
      #     @raise [Git::FailedError] if git returns exit code >= 2 (actual error)
      #
      #   @overload call(no_index: true, path:, **options)
      #     Compare two paths on the filesystem (outside git)
      #
      #     Always use the `path:` keyword for the two filesystem paths so that
      #     paths beginning with `-` are safely separated by `--` and cannot be
      #     mistaken for flags by git.
      #
      #     @example
      #       # git diff --patch --no-index -- <path> <path>
      #       Diff.new(ctx).call(patch: true, no_index: true, path: ['/path/a', '/path/b'])
      #
      #     @param path [Array<String>] two filesystem paths to compare (passed after `--`)
      #
      #     @param options [Hash] command options
      #
      #     @return [Git::CommandLineResult] the result of calling `git diff`
      #
      #     @raise [Git::FailedError] if git returns exit code >= 2 (actual error)
      #
      #   @overload call(commit = nil, cached:, **options)
      #     Compare the index to HEAD or the named commit
      #
      #     @example
      #       # git diff --patch --cached [<commit>]
      #       Diff.new(ctx).call(patch: true, cached: true)
      #       Diff.new(ctx).call('HEAD~3', patch: true, cached: true)
      #
      #     @param commit [String, nil] commit to compare the index against (defaults to HEAD)
      #
      #     @param options [Hash] command options
      #
      #     @return [Git::CommandLineResult] the result of calling `git diff`
      #
      #     @raise [Git::FailedError] if git returns exit code >= 2 (actual error)
      #
      #   @overload call(commit, **options)
      #     Compare the working tree to the named commit
      #
      #     @example
      #       # git diff --numstat --shortstat <commit>
      #       Diff.new(ctx).call('HEAD~3', numstat: true, shortstat: true)
      #
      #     @param commit [String] commit reference to compare the working tree against
      #
      #     @param options [Hash] command options
      #
      #     @return [Git::CommandLineResult] the result of calling `git diff`
      #
      #     @raise [Git::FailedError] if git returns exit code >= 2 (actual error)
      #
      #   @overload call(commit, *commits, **options)
      #     Compare two or more commits, or show a combined diff for a merge commit
      #
      #     @example Compare two commits
      #       # git diff --raw --numstat --shortstat <commit> <commit>
      #       Diff.new(ctx).call('abc123', 'def456', raw: true, numstat: true, shortstat: true)
      #       Diff.new(ctx).call('v1.0..v2.0', raw: true, numstat: true, shortstat: true)
      #
      #     @example Combined diff of a merge commit (three or more commits)
      #       # git diff [--merge-base] <commit> [<commit>...] <commit>
      #       Diff.new(ctx).call('main', 'feature-a', 'feature-b', merge_base: true)
      #
      #     @param commit [String] first commit reference
      #
      #     @param commits [Array<String>] additional commit references
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :patch (nil) Include unified diff patches per file
      #
      #     @option options [Boolean] :numstat (nil) Include per-file insertion/deletion counts
      #
      #     @option options [Boolean] :raw (nil) Include per-file mode/SHA/status metadata
      #
      #     @option options [Boolean] :shortstat (nil) Include aggregate totals line
      #
      #     @option options [String] :src_prefix (nil) Source prefix for diff headers (e.g. `'a/'`)
      #
      #     @option options [String] :dst_prefix (nil) Destination prefix for diff headers (e.g. `'b/'`)
      #
      #     @option options [Boolean] :cached (nil) Compare the index to HEAD or a named commit
      #
      #       Alias: :staged
      #
      #     @option options [Boolean] :merge_base (nil) Use merge base of commits
      #
      #     @option options [Boolean] :no_index (nil) Compare two filesystem paths outside a repo
      #
      #     @option options [Boolean, String] :find_renames (nil) Detect renames, optionally
      #       specifying a similarity threshold (e.g., `'50'` for 50%)
      #
      #       Alias: :M
      #
      #     @option options [Boolean, String] :find_copies (nil) Detect copies as well as renames,
      #       optionally specifying a similarity threshold (e.g., `'75'` for 75%)
      #
      #       Alias: :C
      #
      #     @option options [Boolean] :find_copies_harder (nil) Inspect all files as copy sources
      #
      #     @option options [Boolean, String] :dirstat (nil) Include directory statistics
      #
      #       Pass `true` for default, or a string like `'lines,cumulative'` for options.
      #
      #     @option options [Array<String>] :path (nil) Zero or more paths to limit diff to
      #
      #       Alias: :pathspecs
      #
      #     @return [Git::CommandLineResult] the result of calling `git diff`
      #
      #     @raise [Git::FailedError] if git returns exit code >= 2 (actual error)
    end
  end
end
