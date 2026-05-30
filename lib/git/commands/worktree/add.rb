# frozen_string_literal: true

require 'git/commands/worktree/management_base'

module Git
  module Commands
    module Worktree
      # Creates a new linked worktree
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
      # @note `arguments` block audited against https://git-scm.com/docs/git-worktree/2.54.0
      #
      # @see Git::Commands::Worktree Git::Commands::Worktree for the full sub-command list
      #
      # @see https://git-scm.com/docs/git-worktree git-worktree documentation
      #
      # @api private
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
        #     @option options [Boolean, Integer, nil] :force (nil) override safety guards
        #
        #       Pass `true` or `1` to emit `--force` once. Pass `2` to emit
        #       `--force --force`, which also allows adding worktrees for locked branches.
        #
        #       Alias: :f
        #
        #     @option options [String] :b (nil) create a new branch with this name
        #       and check it out
        #
        #     @option options [String] :B (nil) create or reset a branch with this
        #       name and check it out
        #
        #     @option options [Boolean, nil] :detach (nil) check out in
        #       detached-HEAD state
        #
        #       Alias: :d
        #
        #     @option options [Boolean, nil] :checkout (nil) control whether the working
        #       tree is checked out after creation (`--checkout`)
        #
        #     @option options [Boolean, nil] :no_checkout (nil) suppress the initial
        #       checkout after worktree creation (`--no-checkout`)
        #
        #     @option options [Boolean, nil] :guess_remote (nil) base new branch on a
        #       matching remote-tracking branch (`--guess-remote`)
        #
        #       Applied when no `commit_ish` argument is provided.
        #
        #     @option options [Boolean, nil] :no_guess_remote (nil) disable guess-remote
        #       behavior (`--no-guess-remote`)
        #
        #     @option options [Boolean, nil] :relative_paths (nil) link worktrees using
        #       relative paths (`--relative-paths`)
        #
        #       Overrides the `worktree.useRelativePaths` config option.
        #
        #     @option options [Boolean, nil] :no_relative_paths (nil) use absolute paths
        #       for worktree links (`--no-relative-paths`)
        #
        #       Overrides the `worktree.useRelativePaths` config option.
        #
        #     @option options [Boolean, nil] :track (nil) mark the upstream branch for
        #       tracking (`--track`)
        #
        #     @option options [Boolean, nil] :no_track (nil) do not mark the upstream
        #       branch for tracking (`--no-track`)
        #
        #     @option options [Boolean, nil] :lock (nil) lock the worktree immediately
        #       after creation
        #
        #     @option options [Boolean, nil] :orphan (nil) create an empty worktree
        #       associated with a new unborn branch
        #
        #     @option options [Boolean, nil] :quiet (nil) suppress informational messages
        #
        #       Alias: :q
        #
        #     @option options [String] :reason (nil) explanation for why the worktree
        #       is locked
        #
        #       Only meaningful when used with `:lock`.
        #
        #     @return [Git::CommandLineResult] the result of calling `git worktree add`
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
