# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Remove untracked files from the working tree
    #
    # This command removes files from the working directory that are not tracked by Git.
    # It respects standard ignore rules unless explicitly overridden.
    #
    # @see https://git-scm.com/docs/git-clean git-clean
    #
    # @see Git::Commands
    #
    # @api private
    #
    # @example Clean untracked files
    #   clean = Git::Commands::Clean.new(execution_context)
    #   clean.call
    #
    # @example Force cleaning of untracked files
    #   clean.call(force: true)
    #
    # @example Force cleaning of untracked nested git repositories
    #   clean.call(force: 2)
    #
    # @example Recurse into untracked directories
    #   clean.call(d: true)
    #
    # @example Don’t use the standard ignore rules
    #   clean.call(x: true)
    #
    # @example Dry run — show what would be done without removing anything
    #   clean.call(dry_run: true)
    #
    # @example Exclude files matching a pattern from cleaning
    #   clean.call(force: true, exclude: '*.log')
    #
    # @example Remove only files ignored by Git
    #   clean.call(force: true, X: true)
    #
    # @example Clean specific paths only
    #   clean.call(force: true, pathspec: ['tmp/', 'build/'])
    #
    class Clean < Git::Commands::Base
      arguments do
        literal 'clean'
        flag_option :d
        flag_option %i[force f], max_times: 2
        flag_option %i[dry_run n]
        value_option %i[exclude e], inline: true, repeatable: true
        flag_option :x
        flag_option :X
        end_of_options
        value_option :pathspec, as_operand: true, repeatable: true
      end

      # @!method call(*, **)
      #
      #   @overload call(**options)
      #
      #     Execute the git clean command
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :d (nil) Recurse into untracked directories
      #
      #     @option options [Boolean, Integer] :force (nil) Force the removal of untracked files
      #
      #       When `clean.requireForce` is not set to `false`, git-clean will refuse to
      #       delete files or directories unless this option is given.
      #
      #       Pass `true` or `1` to emit `--force` once. Pass `2` to emit `--force --force`,
      #       which also removes untracked nested git repositories (directories with a
      #       `.git` subdirectory).
      #
      #       Alias: :f
      #
      #     @option options [Boolean] :dry_run (nil) Don't actually remove anything, just
      #       show what would be done
      #
      #     @option options [String, Array<String>] :exclude (nil) Use the given exclude pattern
      #       in addition to the standard ignore rules
      #
      #       May be specified multiple times
      #
      #     @option options [Boolean] :x (nil) Don't use the standard ignore rules
      #
      #       Mutually exclusive with `:X`
      #
      #     @option options [Boolean] :X (nil) Remove only files ignored by Git
      #
      #       Mutually exclusive with `:x`
      #
      #     @option options [String, Array<String>] :pathspec (nil) Limit cleaning to files
      #       matching the given pathspec(s)
      #
      #     @return [Git::CommandLineResult] the result of calling `git clean`
      #
      #     @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      #   @api public
    end
  end
end
