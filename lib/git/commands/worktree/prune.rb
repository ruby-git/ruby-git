# frozen_string_literal: true

require 'git/commands/worktree/management_base'

module Git
  module Commands
    module Worktree
      # Prunes stale worktree administrative files
      #
      # @example Prune stale worktree info
      #   Git::Commands::Worktree::Prune.new(execution_context).call
      #
      # @example Dry-run to see what would be pruned
      #   Git::Commands::Worktree::Prune.new(execution_context).call(dry_run: true)
      #
      # @example Prune entries older than 2 weeks
      #   Git::Commands::Worktree::Prune.new(execution_context).call(expire: '2.weeks.ago')
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-worktree/2.53.0
      #
      # @see Git::Commands::Worktree Git::Commands::Worktree for the full sub-command list
      #
      # @see https://git-scm.com/docs/git-worktree git-worktree documentation
      #
      # @api private
      #
      class Prune < ManagementBase
        arguments do
          literal 'worktree'
          literal 'prune'
          flag_option %i[dry_run n]
          flag_option %i[verbose v]
          value_option :expire
        end

        # @!method call(*, **)
        #
        #   @overload call(**options)
        #
        #     Prune stale worktree administrative files
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :dry_run (nil) report what would be removed
        #       without removing anything
        #
        #       Alias: :n
        #
        #     @option options [Boolean] :verbose (nil) report all removals
        #
        #       Alias: :v
        #
        #     @option options [String] :expire (nil) only prune entries older than
        #       this time expression
        #
        #     @return [Git::CommandLineResult] the result of calling `git worktree prune`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
