# frozen_string_literal: true

require 'git/commands/arguments'
require 'git/diff_parser'

module Git
  module Commands
    module Diff
      # Show numstat (line counts) for differences
      #
      # Returns per-file insertion/deletion counts in machine-readable format.
      #
      # @see Git::Commands::Diff Git::Commands::Diff for usage examples
      #
      # @see https://git-scm.com/docs/git-diff git-diff documentation
      #
      # @api private
      #
      class Numstat
        # Arguments DSL for building command-line arguments
        ARGS = Arguments.define do
          static 'diff'
          static '--numstat'
          static '--shortstat'
          static '-M'
          flag %i[cached staged]
          flag :merge_base
          flag :no_index
          flag_or_value :dirstat, inline: true
          positional :commit1
          positional :commit2
          value :pathspecs, positional: true, separator: '--', multi_valued: true
        end.freeze

        # Creates a new Numstat command instance
        #
        # @param execution_context [Git::ExecutionContext] the execution context for running commands
        #
        def initialize(execution_context)
          @execution_context = execution_context
        end

        # Show diff numstat
        #
        # @overload call(**options)
        #   Compare the index to the working tree
        #
        #   @example
        #     # git diff [-- <pathspecs>...]
        #     Numstat.new(ctx).call
        #     Numstat.new(ctx).call(pathspecs: ['lib/', '*.rb'])
        #
        #   @param options [Hash] command options
        #
        #   @option options [Array<String>] :pathspecs (nil) zero or more pathspecs to limit diff to
        #
        #   @option options [Boolean, String] :dirstat (nil) include directory statistics.
        #     Pass true for default, or a string like 'lines,cumulative' for options.
        #
        # @overload call(path1, path2, no_index: true, **options)
        #   Compare two paths on the filesystem (outside git)
        #
        #   @example
        #     # git diff --no-index <path> <path> [<pathspec>...]
        #     Numstat.new(ctx).call('/path/a', '/path/b', no_index: true)
        #     Numstat.new(ctx).call('/dir/a', '/dir/b', no_index: true, pathspecs: ['*.rb'])
        #
        #   @param path1 [String] first filesystem path
        #
        #   @param path2 [String] second filesystem path
        #
        #   @param no_index [Boolean] must be true
        #
        #   @param options [Hash] command options
        #
        #   @option options [Array<String>] :pathspecs (nil) when comparing directories, zero or more
        #     relative pathspecs to limit diff to (applies to both sides)
        #
        #   @option options [Boolean, String] :dirstat (nil) include directory statistics.
        #     Pass true for default, or a string like 'lines,cumulative' for options.
        #
        # @overload call(commit = nil, cached:, **options)
        #   Compare the index to HEAD or the named commit
        #
        #   @example
        #     # git diff --cached [<commit>] [-- <pathspecs>...]
        #     Numstat.new(ctx).call(cached: true)
        #     Numstat.new(ctx).call('HEAD~3', cached: true, pathspecs: ['lib/'])
        #
        #   @param commit [String] optional commit reference (defaults to HEAD)
        #
        #   @param cached [Boolean] must be true (alias: :staged)
        #
        #   @param options [Hash] command options
        #
        #   @option options [Array<String>] :pathspecs (nil) zero or more pathspecs to limit diff to
        #
        #   @option options [Boolean, String] :dirstat (nil) include directory statistics.
        #     Pass true for default, or a string like 'lines,cumulative' for options.
        #
        # @overload call(commit, **options)
        #   Compare the working tree to the named commit
        #
        #   @example
        #     # git diff <commit> [-- <pathspecs>...]
        #     Numstat.new(ctx).call('HEAD~3')
        #     Numstat.new(ctx).call('abc123', pathspecs: ['lib/', '*.rb'])
        #
        #   @param commit [String] commit reference
        #
        #   @param options [Hash] command options
        #
        #   @option options [Array<String>] :pathspecs (nil) zero or more pathspecs to limit diff to
        #
        #   @option options [Boolean, String] :dirstat (nil) include directory statistics.
        #     Pass true for default, or a string like 'lines,cumulative' for options.
        #
        # @overload call(commit1, commit2, **options)
        #   Compare two commits
        #
        #   @example
        #     # git diff <commit> <commit> [-- <pathspecs>...]
        #     # git diff <commit>..<commit> [-- <pathspecs>...]
        #     # git diff <commit>...<commit> [-- <pathspecs>...]
        #     Numstat.new(ctx).call('abc123', 'def456')
        #     Numstat.new(ctx).call('v1.0..v2.0')   # two-dot range syntax
        #     Numstat.new(ctx).call('main...feature')  # three-dot (merge-base) syntax
        #
        #   @param commit1 [String] first commit reference (or range string like 'main..feature')
        #
        #   @param commit2 [String] second commit reference (omit if commit1 is a range)
        #
        #   @param options [Hash] command options
        #
        #   @option options [Array<String>] :pathspecs (nil) zero or more pathspecs to limit diff to
        #
        #   @option options [Boolean] :merge_base (false) use merge base of commits
        #     (alternative to three-dot syntax)
        #
        #   @option options [Boolean, String] :dirstat (nil) include directory statistics.
        #     Pass true for default, or a string like 'lines,cumulative' for options.
        #
        # @overload call(merge_commit, range, **options)
        #   Show changes introduced by a merge commit beyond the merged branches
        #
        #   @example
        #     # git diff <merge-commit> <commit>...<commit> [-- <pathspecs>...]
        #     Numstat.new(ctx).call('merge_commit', 'main...feature')
        #
        #   @param merge_commit [String] merge commit reference
        #
        #   @param range [String] three-dot range of merged branches
        #
        #   @param options [Hash] command options
        #
        #   @option options [Array<String>] :pathspecs (nil) zero or more pathspecs to limit diff to
        #
        #   @option options [Boolean, String] :dirstat (nil) include directory statistics.
        #     Pass true for default, or a string like 'lines,cumulative' for options.
        #
        # @return [Git::DiffResult] diff result with per-file and total statistics
        #
        # @raise [Git::FailedError] if git returns exit code >= 2 (actual error)
        #
        def call(*, **)
          bound_args = ARGS.bind(*, **)

          # git diff exit codes: 0 = no diff, 1 = diff found, 2+ = error
          result = @execution_context.command(*bound_args, raise_on_failure: false)
          raise Git::FailedError, result if result.status.exitstatus >= 2

          DiffParser::Numstat.parse(result.stdout, include_dirstat: !bound_args.dirstat.nil?)
        end
      end
    end
  end
end
