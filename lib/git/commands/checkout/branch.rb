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
      # @example Typical usage
      #   checkout = Git::Commands::Checkout::Branch.new(execution_context)
      #   checkout.call('main')
      #   checkout.call(b: 'feature-branch')
      #   checkout.call('origin/main', b: 'feature-branch', track: true)
      #   checkout.call('abc123', detach: true)
      #   checkout.call('main', force: true)
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-checkout/2.53.0
      #
      # @see Git::Commands::Checkout
      #
      # @see https://git-scm.com/docs/git-checkout git-checkout
      #
      # @api private
      #
      class Branch < Git::Commands::Base
        arguments do
          literal 'checkout'
          flag_option %i[quiet q]
          flag_option :progress, negatable: true
          flag_option %i[force f]
          value_option :b
          value_option :B
          flag_or_value_option %i[track t], negatable: true, inline: true
          flag_option :guess, negatable: true
          flag_option :l
          flag_option %i[detach d]
          value_option :orphan
          flag_option %i[merge m]
          flag_option :ignore_other_worktrees
          flag_option :overwrite_ignore, negatable: true

          # --recurse-submodules is technically available but has no effect on branch
          # switching in older git versions. Included for completeness per the man page.
          flag_option :recurse_submodules, negatable: true

          execution_option :chdir

          operand :branch
        end

        # @overload call(branch = nil, **options)
        #
        #     Execute the git checkout command for branch switching
        #
        #     @param branch [String, nil] the branch name, commit SHA, or ref to check
        #       out; when used with branch creation options (`:b`, `:B`, `:orphan`)
        #       this becomes the start point
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean, nil] :quiet (nil) suppress feedback messages
        #
        #       Alias: `:q`
        #
        #     @option options [Boolean, nil] :progress (nil) force progress reporting even
        #       when not attached to a terminal (`--progress`)
        #
        #     @option options [Boolean, nil] :no_progress (nil) disable progress reporting
        #       even when attached to a terminal (`--no-progress`)
        #
        #     @option options [Boolean, nil] :force (nil) proceed even if the index or
        #       working tree differs from HEAD; discards local changes and untracked
        #       files that are in the way
        #
        #       Alias: `:f`
        #
        #     @option options [String] :b (nil) create a new branch with this name and
        #       switch to it; the positional `branch` argument becomes the start point
        #
        #     @option options [String] :B (nil) like `:b`, but reset the branch to the
        #       start point if it already exists
        #
        #     @option options [Boolean, String, nil] :track (nil) set up upstream tracking
        #       configuration; `true` emits `--track`, `'direct'` emits
        #       `--track=direct`, `'inherit'` emits `--track=inherit` (`--track`)
        #
        #       Alias: `:t`
        #
        #     @option options [Boolean, nil] :no_track (nil) do not set up branch tracking
        #       even if `branch.autoSetupMerge` is configured (`--no-track`)
        #
        #     @option options [Boolean, nil] :guess (nil) automatically create and check out
        #       a local branch from a uniquely matching remote-tracking branch
        #       (`--guess`)
        #
        #     @option options [Boolean, nil] :no_guess (nil) disable automatic remote branch
        #       matching (`--no-guess`)
        #
        #     @option options [Boolean, nil] :l (nil) create the new branch's reflog
        #
        #     @option options [Boolean, nil] :detach (nil) detach HEAD at the specified
        #       commit rather than pointing a branch at it
        #
        #       Alias: `:d`
        #
        #     @option options [String] :orphan (nil) create a new unborn branch with no
        #       history; the positional `branch` argument becomes the start point
        #
        #     @option options [Boolean, nil] :merge (nil) perform a three-way merge when
        #       local modifications conflict with the target branch
        #
        #       Alias: `:m`
        #
        #     @option options [Boolean, nil] :ignore_other_worktrees (nil) check out the
        #       branch even if it is already in use by another worktree
        #
        #     @option options [Boolean, nil] :overwrite_ignore (nil) silently overwrite
        #       ignored files when switching branches (`--overwrite-ignore`)
        #
        #     @option options [Boolean, nil] :no_overwrite_ignore (nil) abort the checkout
        #       if ignored files would be overwritten (`--no-overwrite-ignore`)
        #
        #     @option options [Boolean, nil] :recurse_submodules (nil) update all active
        #       submodule working trees to match the new branch
        #       (`--recurse-submodules`)
        #
        #     @option options [Boolean, nil] :no_recurse_submodules (nil) do not update
        #       submodule working trees when switching branches
        #       (`--no-recurse-submodules`)
        #
        #     @option options [String] :chdir (nil) change to this directory before
        #       running git; not passed to the git CLI
        #
        #     @return [Git::CommandLine::Result] the result of calling `git checkout`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
        #
        #   @api public
        #
        def call(*, **)
          super
        end
      end
    end
  end
end
