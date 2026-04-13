# frozen_string_literal: true

require 'git/commands/worktree/management_base'

module Git
  module Commands
    module Worktree
      # Creates a new linked worktree
      #
      # @see Git::Commands::Worktree Git::Commands::Worktree for the full sub-command list
      # @see https://git-scm.com/docs/git-worktree git-worktree documentation
      #
      # @api private
      #
      # @example Add a worktree at a path (auto-creates a branch)
      #   Git::Commands::Worktree::Add.new(execution_context).call('/tmp/feature')
      #
      # @example Add a worktree and check out an existing branch
      #   Git::Commands::Worktree::Add.new(execution_context).call('/tmp/hotfix', 'main')
      #
      # @example Add a worktree with a new branch
      #   Git::Commands::Worktree::Add.new(execution_context).call('/tmp/feat', b: 'feature/new')
      #
      # @example Add a detached-HEAD worktree locked at creation
      #   Git::Commands::Worktree::Add.new(execution_context).call('/tmp/exp', detach: true, lock: true)
      #
      class Add < ManagementBase
        arguments do
          literal 'worktree'
          literal 'add'
          flag_option %i[force f], max_times: 2
          value_option :b
          value_option :B
          flag_option %i[detach d]
          flag_option :checkout, negatable: true
          flag_option :guess_remote, negatable: true
          flag_option :relative_paths, negatable: true
          flag_option :track, negatable: true
          flag_option :lock
          flag_option :orphan
          flag_option %i[quiet q]
          value_option :reason
          end_of_options
          operand :path, required: true
          operand :commit_ish
        end

        # @!method call(*, **)
        #
        #   @overload call(path, commit_ish = nil, **options)
        #
        #     Create a new linked worktree and check out `commit_ish` into it
        #
        #     @param path [String] filesystem path for the new worktree
        #
        #     @param commit_ish [String, nil] (nil) branch, tag, or commit to check out
        #
        #       When omitted, git creates a new branch named after the final path
        #       component and checks it out.
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean, Integer] :force (nil) override safety guards
        #
        #       Pass `true` or `1` to emit `--force` once. Pass `2` to emit
        #       `--force --force`, which also allows adding worktrees for locked branches.
        #
        #       Alias: :f
        #
        #     @option options [String] :b (nil) create a new branch with this name and check it out
        #
        #     @option options [String] :B (nil) create or reset a branch with this name and check it out
        #
        #     @option options [Boolean] :detach (nil) check out in detached-HEAD state
        #
        #       Alias: :d
        #
        #     @option options [Boolean] :checkout (nil) control whether the working tree
        #       is checked out after creation
        #
        #       When `false`, passes `--no-checkout`, suppressing the initial checkout.
        #
        #     @option options [Boolean] :guess_remote (nil) base new branch on a matching
        #       remote-tracking branch when no `commit_ish` is given
        #
        #       When `false`, passes `--no-guess-remote`.
        #
        #     @option options [Boolean] :relative_paths (nil) link worktrees using relative paths
        #
        #       When `false`, passes `--no-relative-paths`, using absolute paths instead.
        #       Overrides the `worktree.useRelativePaths` config option.
        #
        #     @option options [Boolean] :track (nil) mark the upstream branch for tracking
        #
        #       When `false`, passes `--no-track`.
        #
        #     @option options [Boolean] :lock (nil) lock the worktree immediately after creation
        #
        #     @option options [Boolean] :orphan (nil) create an empty worktree associated with a new unborn branch
        #
        #     @option options [Boolean] :quiet (nil) suppress informational messages
        #
        #       Alias: :q
        #
        #     @option options [String] :reason (nil) explanation for why the worktree is locked
        #
        #       Only meaningful when used with `:lock`.
        #
        #     @return [Git::CommandLineResult] the result of calling `git worktree add`
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
