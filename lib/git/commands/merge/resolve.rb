# frozen_string_literal: true

require 'git/commands/arguments'

module Git
  module Commands
    module Merge
      # Implements merge state management: abort, continue, or quit an in-progress merge
      #
      # This command handles the resolution of a merge that has stopped due to conflicts:
      # - `--abort`: Abort the merge and restore pre-merge state
      # - `--continue`: Complete the merge after conflicts are resolved
      # - `--quit`: Forget about the merge, leaving working tree as-is
      #
      # @see https://git-scm.com/docs/git-merge git-merge
      #
      # @api private
      #
      # @example Abort a merge
      #   resolve = Git::Commands::Merge::Resolve.new(execution_context)
      #   resolve.call(abort: true)
      #
      # @example Continue after resolving conflicts
      #   resolve.call(continue: true)
      #
      # @example Quit the merge, leaving working tree as-is
      #   resolve.call(quit: true)
      #
      class Resolve
        # Arguments DSL for building command-line arguments
        #
        # NOTE: Exactly one of abort, continue, or quit must be specified.
        #
        ARGS = Arguments.define do
          static 'merge'
          flag :abort, args: '--abort'
          flag :continue, args: '--continue'
          flag :quit, args: '--quit'

          conflicts :abort, :continue, :quit
        end.freeze

        # Initialize the Merge::Resolve command
        #
        # @param execution_context [Git::ExecutionContext, Git::Lib] the context for executing git commands
        #
        def initialize(execution_context)
          @execution_context = execution_context
        end

        # Execute the git merge state management command
        #
        # @overload call(**options)
        #
        #   @param options [Hash] command options (exactly one must be true)
        #
        #   @option options [Boolean] :abort (nil) Abort the current merge and
        #     restore the pre-merge state. If an autostash entry is present,
        #     apply it to the worktree.
        #
        #   @option options [Boolean] :continue (nil) Complete the merge after
        #     conflicts have been resolved and staged.
        #
        #   @option options [Boolean] :quit (nil) Forget about the current merge
        #     in progress. Leave the index and working tree as-is. If an
        #     autostash entry is present, save it to the stash list.
        #
        # @return [String] the command output
        #
        # @raise [Git::FailedError] if the command fails (e.g., no merge in progress,
        #   unresolved conflicts for continue)
        #
        def call(*, **)
          args = ARGS.build(*, **)
          @execution_context.command(*args)
        end
      end
    end
  end
end
