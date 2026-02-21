# frozen_string_literal: true

require 'git/commands/base'
require 'git/parsers/diff'

module Git
  module Commands
    module Diff
      # Show full patch output for differences
      #
      # Returns unified diff patches for each changed file.
      #
      # @see Git::Commands::Diff Git::Commands::Diff for usage examples
      #
      # @see https://git-scm.com/docs/git-diff git-diff documentation
      #
      # @api private
      #
      class Patch < Base
        arguments do
          literal 'diff'
          # These three format literals are always emitted together. Git::Parsers::Diff
          # expects all three sections to be present in every diff command's output:
          # --patch for per-file unified diffs, --numstat for per-file line counts, and
          # --shortstat for aggregate totals. Fixing them here (rather than making them
          # caller-controlled) keeps the parser contract simple and unconditional.
          literal '--patch'
          literal '--numstat'    # always present alongside --patch: parser requires per-file counts
          literal '--shortstat'  # always present alongside --patch: parser requires aggregate totals
          literal '--src-prefix=a/'
          literal '--dst-prefix=b/'
          flag_option %i[cached staged]
          flag_option :merge_base
          flag_option :no_index
          flag_or_value_option %i[find_renames M], inline: true
          flag_or_value_option %i[find_copies C], inline: true
          flag_option :find_copies_harder
          flag_or_value_option :dirstat, inline: true
          # NOTE: git diff uses <commit> for both positional arguments. The DSL requires distinct
          # names for two positional operands, so :commit1 and :commit2 are used here.
          operand :commit1
          operand :commit2
          value_option :pathspecs, as_operand: true, separator: '--', repeatable: true
          conflicts :cached, :no_index
        end

        # git diff exit codes: 0 = no diff, 1 = diff found, 2+ = error
        allow_exit_status 0..1

        # Show diff patch
        #
        # @overload call(**options)
        #   Compare the index to the working tree
        #
        #   @example
        #     # git diff --patch [--] [<path>...]
        #     Patch.new(ctx).call
        #     Patch.new(ctx).call(path: ['lib/', '*.rb'])
        #
        #   @param options [Hash] command options
        #
        #   @option options [Array<String>] :pathspecs (nil) zero or more pathspecs to limit diff to
        #   @option options [Boolean] :find_copies (false) detect copies as well as renames (adds `-C`)
        #   @option options [Boolean, String] :dirstat (nil) include directory statistics.
        #     Pass true for default, or a string like 'lines,cumulative' for options.
        #
        # @overload call(path1, path2, no_index:, **options)
        #   Compare two paths on the filesystem (outside git)
        #
        #   @example
        #     # git diff --no-index [--] <path> <path>
        #     Patch.new(ctx).call('/path/a', '/path/b', no_index: true)
        #
        #   @param path1 [String] first filesystem path
        #   @param path2 [String] second filesystem path
        #   @param no_index [Boolean] must be true
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :find_copies (false) detect copies as well as renames (adds `-C`)
        #   @option options [Boolean, String] :dirstat (nil) include directory statistics.
        #     Pass true for default, or a string like 'lines,cumulative' for options.
        #
        # @overload call(commit = nil, cached:, **options)
        #   Compare the index to HEAD or the named commit
        #
        #   @example
        #     # git diff --patch --cached [<commit>] [--] [<path>...]
        #     Patch.new(ctx).call(cached: true)
        #     Patch.new(ctx).call('HEAD~3', cached: true, path: ['lib/'])
        #
        #   @param commit [String] optional commit reference (defaults to HEAD)
        #   @param cached [Boolean] must be true (alias: :staged)
        #   @param options [Hash] command options
        #
        #   @option options [Array<String>] :pathspecs (nil) zero or more pathspecs to limit diff to
        #
        #   @option options [Boolean] :find_copies (false) detect copies as well as renames (adds `-C`)
        #
        #   @option options [Boolean, String] :dirstat (nil) include directory statistics.
        #     Pass true for default, or a string like 'lines,cumulative' for options.
        #
        # @overload call(commit, **options)
        #   Compare the working tree to the named commit
        #
        #   @example
        #     # git diff --patch <commit> [--] [<path>...]
        #     Patch.new(ctx).call('HEAD~3')
        #     Patch.new(ctx).call('abc123', path: ['lib/', '*.rb'])
        #
        #   @param commit [String] commit reference
        #   @param options [Hash] command options
        #
        #   @option options [Array<String>] :pathspecs (nil) zero or more pathspecs to limit diff to
        #
        #   @option options [Boolean] :find_copies (false) detect copies as well as renames (adds `-C`)
        #
        #   @option options [Boolean, String] :dirstat (nil) include directory statistics.
        #     Pass true for default, or a string like 'lines,cumulative' for options.
        #
        # @overload call(commit1, commit2, **options)
        #   Compare two commits
        #
        #   @example
        #     # git diff --patch <commit> <commit> [--] [<path>...]
        #     # git diff --patch <commit>..<commit> [--] [<path>...]
        #     # git diff --patch <commit>...<commit> [--] [<path>...]
        #     Patch.new(ctx).call('abc123', 'def456')
        #     Patch.new(ctx).call('v1.0..v2.0')   # two-dot range syntax
        #     Patch.new(ctx).call('main...feature')  # three-dot (merge-base) syntax
        #
        #   @param commit1 [String] first commit reference (or range string like 'main..feature')
        #   @param commit2 [String] second commit reference (omit if commit1 is a range)
        #   @param options [Hash] command options
        #
        #   @option options [Array<String>] :pathspecs (nil) zero or more pathspecs to limit diff to
        #
        #   @option options [Boolean] :merge_base (false) use merge base of commits
        #     (alternative to three-dot syntax)
        #
        #   @option options [Boolean] :find_copies (false) detect copies as well as renames (adds `-C`)
        #
        #   @option options [Boolean, String] :dirstat (nil) include directory statistics.
        #     Pass true for default, or a string like 'lines,cumulative' for options.
        #
        # @overload call(merge_commit, range, **options)
        #   Show changes introduced by a merge commit beyond the merged branches
        #
        #   @example
        #     # git diff --patch <merge-commit> <commit>...<commit> [--] [<path>...]
        #     Patch.new(ctx).call('merge_commit', 'main...feature')
        #
        #   @param merge_commit [String] merge commit reference
        #   @param range [String] three-dot range of merged branches
        #   @param options [Hash] command options
        #
        #   @option options [Array<String>] :pathspecs (nil) zero or more pathspecs to limit diff to
        #
        #   @option options [Boolean] :find_copies (false) detect copies as well as renames (adds `-C`)
        #
        #   @option options [Boolean, String] :dirstat (nil) include directory statistics.
        #     Pass true for default, or a string like 'lines,cumulative' for options.
        #
        # @return [Git::CommandLineResult] the result of calling `git diff --patch`
        #
        # @raise [Git::FailedError] if git returns exit code >= 2 (actual error)
        #
        def call(...) = super # rubocop:disable Lint/UselessMethodDefinition
      end
    end
  end
end
