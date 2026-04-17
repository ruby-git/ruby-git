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
      # @note `arguments` block audited against https://git-scm.com/docs/git-worktree/2.53.0
      #
      # @see Git::Commands::Worktree
      #
      # @see https://git-scm.com/docs/git-worktree git-worktree documentation
      #
      # @api private
      #
      class List < Git::Commands::Base
        arguments do
          literal 'worktree'
          literal 'list'
          flag_option :porcelain
          flag_option :z
          flag_option %i[verbose v]
          value_option :expire
        end

        # @!method call(*, **)
        #
        #   @overload call(**options)
        #
        #     List all worktrees attached to the repository
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :porcelain (false) produce machine-readable output
        #
        #     @option options [Boolean] :z (false) NUL-terminate lines (use with `:porcelain`)
        #
        #     @option options [Boolean] :verbose (false) output additional information about worktrees
        #
        #       Alias: :v
        #
        #     @option options [String] :expire (nil) annotate missing worktrees as prunable if older than
        #       this time expression
        #
        #     @return [Git::CommandLineResult] the result of calling `git worktree list`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
