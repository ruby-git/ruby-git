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
    #   clean.call(force_force: true)
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
    class Clean < Base
      arguments do
        literal 'clean'
        flag_option :d
        flag_option %i[force f]
        flag_option %i[force_force ff], as: '-ff'
        flag_option %i[dry_run n]
        value_option %i[exclude e], inline: true, repeatable: true
        flag_option :x
        flag_option :X
        value_option :pathspec, as_operand: true, separator: '--', repeatable: true
        conflicts :x, :X
      end

      # Execute the git clean command
      #
      # @overload call(**options)
      #
      #   @param options [Hash] command options
      #
      #   @option options [Boolean] :d (nil) Recurse into untracked directories
      #
      #   @option options [Boolean] :force (nil) Force the clean operation when clean.requireForce is
      #     not set to false. If the Git configuration variable `clean.requireForce` is not set to `false`,
      #     git clean will refuse to delete files or directories unless given `-f`.
      #     Alias: :f
      #
      #   @option options [Boolean] :force_force (nil) Remove untracked nested git repositories
      #     (directories with a .git subdirectory). Alias: :ff
      #
      #   @option options [Boolean] :dry_run (nil) Don't actually remove anything, just show what
      #     would be done. Alias: :n
      #
      #   @option options [String, Array<String>] :exclude (nil) Use the given exclude pattern in
      #     addition to the standard ignore rules. May be specified multiple times. Alias: :e
      #
      #   @option options [Boolean] :x (nil) Don't use the standard ignore rules (see gitignore).
      #     Mutually exclusive with :X
      #
      #   @option options [Boolean] :X (nil) Remove only files ignored by Git.
      #     Mutually exclusive with :x
      #
      #   @option options [String, Array<String>] :pathspec (nil) Limit cleaning to files
      #     matching the given pathspec(s)
      #
      # @return [Git::CommandLineResult] the result of calling `git clean`
      #
      # @raise [Git::FailedError] if the command returns a non-zero exit status
      #
      def call(...) = super # rubocop:disable Lint/UselessMethodDefinition
    end
  end
end
