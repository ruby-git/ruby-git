# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Worktree
      # Lists all worktrees attached to the repository
      #
      # @example List all worktrees in porcelain format
      #   Git::Commands::Worktree::List.new(execution_context).call(porcelain: true)
      #
      # @see Git::Commands::Worktree Git::Commands::Worktree for the full sub-command list
      # @see https://git-scm.com/docs/git-worktree git-worktree documentation
      #
      # @api private
      #
      class List < Git::Commands::Base
        arguments do
          literal 'worktree'
          literal 'list'
          flag_option :porcelain
        end

        # @!method call(*, **)
        #
        #   @overload call(**options)
        #
        #     List all worktrees attached to the repository
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :porcelain (nil) produce machine-readable output
        #
        #     @return [Git::CommandLineResult] the result of calling `git worktree list`
        #
        #     @raise [Git::FailedError] if git exits with a non-zero status
      end
    end
  end
end
