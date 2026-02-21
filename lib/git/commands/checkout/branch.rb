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
      #   checkout.call(b: 'feature-branch')
      #
      # @example Create a branch from a specific start point
      #   checkout.call('origin/main', b: 'feature-branch', track: true)
      #
      # @example Detach HEAD at a specific commit
      #   checkout.call('abc123', detach: true)
      #
      # @example Force checkout, discarding local changes
      #   checkout.call('main', force: true)
      #
      class Branch < Git::Commands::Base
        arguments do
          literal 'checkout'
          flag_option %i[force f]
          flag_option %i[merge m]

          # Branch creation options (mutually exclusive)
          # These use `value` (not `value :name, inline: true`) because git expects: -b <branch>, not -b=<branch>
          value_option :b
          value_option :B

          # Tracking options
          flag_or_value_option %i[track t], negatable: true, inline: true

          # Other options
          flag_option :guess, negatable: true
          flag_option %i[detach d]
          value_option :orphan
          flag_option :ignore_other_worktrees
          flag_option :recurse_submodules, negatable: true

          conflicts :b, :B, :orphan

          # Positional arguments
          operand :branch
        end

        # @!method call(*, **)
        #
        #   Execute the git checkout command for branch switching
        #
        #   @overload call(branch = nil, **options)
        #
        #     @param branch [String, nil] The branch name, commit SHA, or ref to
        #       checkout. When used with branch creation options, this becomes the
        #       start point.
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :force (nil) Proceed even if the index or
        #       working tree differs from HEAD. Local changes are discarded. Alias: :f
        #
        #     @option options [Boolean] :merge (nil) Perform a three-way merge.
        #       Alias: :m
        #
        #     @option options [String] :b (nil) Create a new branch with this name and switch to it
        #
        #     @option options [String] :'B' (nil) Like :b, but reset if the branch already exists
        #
        #     @option options [Boolean, String] :track (nil) Set up upstream tracking.
        #       true/false for --track/--no-track, or 'direct'/'inherit' for
        #       --track=<value>.
        #       Alias: :t
        #
        #     @option options [Boolean] :guess (nil) Control automatic branch creation
        #       from remotes. true for --guess, false for --no-guess
        #
        #     @option options [Boolean] :detach (nil) Detach HEAD at the specified
        #       commit. Alias: :d
        #
        #     @option options [String] :orphan (nil) Create a new orphan branch with
        #       no history
        #
        #     @option options [Boolean] :ignore_other_worktrees (nil) Allow checking
        #       out a branch checked out in another worktree
        #
        #     @option options [Boolean] :recurse_submodules (nil) Update submodules.
        #       true for --recurse-submodules, false for --no-recurse-submodules
        #
        #     @return [Git::CommandLineResult] the result of the command
        #
        #     @raise [Git::FailedError] if the checkout fails
      end
    end
  end
end
