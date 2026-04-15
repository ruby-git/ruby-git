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
          flag_option %i[quiet q]                                          # --quiet (alias: :q)
          flag_option :progress, negatable: true                           # --progress / --no-progress
          flag_option %i[force f]                                          # --force (alias: :f)
          value_option :b                                                  # -b <new-branch>
          value_option :B                                                  # -B <new-branch>
          flag_or_value_option %i[track t], negatable: true, inline: true  # --track[=(direct|inherit)] / --no-track
          flag_option :guess, negatable: true                              # --guess / --no-guess
          flag_option :l                                                   # -l
          flag_option %i[detach d]                                         # --detach (alias: :d)
          value_option :orphan                                             # --orphan <new-branch>
          flag_option %i[merge m]                                          # --merge (alias: :m)
          flag_option :ignore_other_worktrees                              # --ignore-other-worktrees
          flag_option :overwrite_ignore, negatable: true                   # --overwrite-ignore / --no-overwrite-ignore

          # --recurse-submodules is technically available but has no effect on branch
          # switching in older git versions. Included for completeness per the man page.
          flag_option :recurse_submodules, negatable: true # --recurse-submodules / --no-recurse-submodules

          execution_option :chdir

          operand :branch
        end

        # @!method call(*, **)
        #
        #   @overload call(branch = nil, **options)
        #
        #     Execute the git checkout command for branch switching
        #
        #     @param branch [String, nil] the branch name, commit SHA, or ref to check
        #       out; when used with branch creation options (`:b`, `:B`, `:orphan`)
        #       this becomes the start point
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :quiet (false) suppress feedback messages
        #
        #       Alias: `:q`
        #
        #     @option options [Boolean] :progress (nil) force progress reporting even
        #       when not attached to a terminal; use `false` for `--no-progress`
        #
        #     @option options [Boolean] :force (false) proceed even if the index or
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
        #     @option options [Boolean, String] :track (nil) set up upstream tracking
        #       configuration; `true` emits `--track`, `false` emits `--no-track`, and
        #       `'direct'` or `'inherit'` emits `--track=direct` / `--track=inherit`
        #
        #       Alias: `:t`
        #
        #     @option options [Boolean] :guess (nil) automatically create and check out
        #       a local branch from a uniquely matching remote-tracking branch; use
        #       `false` for `--no-guess`
        #
        #     @option options [Boolean] :l (false) create the new branch's reflog
        #
        #     @option options [Boolean] :detach (false) detach HEAD at the specified
        #       commit rather than pointing a branch at it
        #
        #       Alias: `:d`
        #
        #     @option options [String] :orphan (nil) create a new unborn branch with no
        #       history; the positional `branch` argument becomes the start point
        #
        #     @option options [Boolean] :merge (false) perform a three-way merge when
        #       local modifications conflict with the target branch
        #
        #       Alias: `:m`
        #
        #     @option options [Boolean] :ignore_other_worktrees (false) check out the
        #       branch even if it is already in use by another worktree
        #
        #     @option options [Boolean] :overwrite_ignore (nil) silently overwrite
        #       ignored files when switching branches; use `false` for
        #       `--no-overwrite-ignore`
        #
        #     @option options [Boolean] :recurse_submodules (nil) update all active
        #       submodule working trees to match the new branch; use `false` for
        #       `--no-recurse-submodules`
        #
        #     @option options [String] :chdir (nil) change to this directory before
        #       running git; not passed to the git CLI
        #
        #     @return [Git::CommandLineResult] the result of calling `git checkout`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
        #
        #     @api public
      end
    end
  end
end
