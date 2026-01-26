# frozen_string_literal: true

require 'git/commands/arguments'

module Git
  module Commands
    module Checkout
      # Implements the `git checkout` command for switching branches
      #
      # This command switches branches by updating the index and working tree
      # to match the specified branch, and updating HEAD to point to that branch.
      # It can also create new branches with the `-b` or `-B` options.
      #
      # @see https://git-scm.com/docs/git-checkout git-checkout
      #
      # @api private
      #
      # @example Switch to an existing branch
      #   checkout = Git::Commands::Checkout::Branch.new(execution_context)
      #   checkout.call('main')
      #
      # @example Create and switch to a new branch
      #   checkout.call(new_branch: 'feature-branch')
      #
      # @example Create a branch from a specific start point
      #   checkout.call('origin/main', new_branch: 'feature-branch', track: true)
      #
      # @example Detach HEAD at a specific commit
      #   checkout.call('abc123', detach: true)
      #
      # @example Force checkout, discarding local changes
      #   checkout.call('main', force: true)
      #
      class Branch
        # Arguments DSL for building command-line arguments
        #
        # NOTE: The order of definitions determines the order of arguments
        # in the final command line.
        #
        ARGS = Arguments.define do
          static 'checkout'
          flag %i[force f], args: '--force'
          flag %i[merge m], args: '--merge'
          flag %i[detach d], args: '--detach'

          # Branch creation options (mutually exclusive)
          # These use `value` (not `inline_value`) because git expects: -b <branch>, not -b=<branch>
          value %i[new_branch b], args: '-b'
          value %i[new_branch_force B], args: '-B'
          value :orphan, args: '--orphan'

          # Tracking options
          negatable_flag_or_inline_value :track

          # Other options
          negatable_flag :guess
          flag :ignore_other_worktrees, args: '--ignore-other-worktrees'
          negatable_flag :recurse_submodules

          # Positional arguments
          positional :branch
        end.freeze

        # Initialize the Branch command
        #
        # @param execution_context [Git::ExecutionContext, Git::Lib] the context for executing git commands
        #
        def initialize(execution_context)
          @execution_context = execution_context
        end

        # Execute the git checkout command for branch switching
        #
        # @overload call(branch = nil, **options)
        #
        #   @param branch [String, nil] The branch name, commit SHA, or ref to
        #     checkout. When used with branch creation options, this becomes the
        #     start point.
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :force (nil) Proceed even if the index or
        #     working tree differs from HEAD. Local changes are discarded. Alias: :f
        #
        #   @option options [Boolean] :merge (nil) Perform a three-way merge.
        #     Alias: :m
        #
        #   @option options [Boolean] :detach (nil) Detach HEAD at the specified
        #     commit. Alias: :d
        #
        #   @option options [String] :new_branch (nil) Create a new branch with this
        #     name and switch to it. Alias: :b
        #
        #   @option options [String] :new_branch_force (nil) Like :new_branch, but
        #     reset if the branch exists. Alias: :B
        #
        #   @option options [String] :orphan (nil) Create a new orphan branch with
        #     no history
        #
        #   @option options [Boolean, String] :track (nil) Set up upstream tracking.
        #     true/false for --track/--no-track, or 'direct'/'inherit' for
        #     --track=<value>
        #
        #   @option options [Boolean] :guess (nil) Control automatic branch creation
        #     from remotes. true for --guess, false for --no-guess
        #
        #   @option options [Boolean] :ignore_other_worktrees (nil) Allow checking
        #     out a branch checked out in another worktree
        #
        #   @option options [Boolean] :recurse_submodules (nil) Update submodules.
        #     true for --recurse-submodules, false for --no-recurse-submodules
        #
        # @return [String] the command output (typically empty on success)
        #
        # @raise [Git::FailedError] if the checkout fails
        #
        def call(*, **)
          args = ARGS.build(*, **)
          @execution_context.command(*args)
        end
      end
    end
  end
end
