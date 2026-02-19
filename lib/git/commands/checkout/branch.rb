# frozen_string_literal: true

require 'git/commands/base'

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
      class Branch < Base
        arguments do
          literal 'checkout'
          flag_option %i[force f], as: '--force'
          flag_option %i[merge m], as: '--merge'
          flag_option %i[detach d], as: '--detach'

          # Branch creation options (mutually exclusive)
          # These use `value` (not `value :name, inline: true`) because git expects: -b <branch>, not -b=<branch>
          value_option %i[new_branch b], as: '-b'
          value_option %i[new_branch_force B], as: '-B'
          value_option :orphan, as: '--orphan'

          # Tracking options
          flag_or_value_option :track, negatable: true, inline: true

          # Other options
          flag_option :guess, negatable: true
          flag_option :ignore_other_worktrees, as: '--ignore-other-worktrees'
          flag_option :recurse_submodules, negatable: true

          # Positional arguments
          operand :branch
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
        # @return [Git::CommandLineResult] the result of the command
        #
        # @raise [Git::FailedError] if the checkout fails
        #
        def call(...) = super # rubocop:disable Lint/UselessMethodDefinition
      end
    end
  end
end
