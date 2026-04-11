# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Worktree
      # Lists all worktrees attached to the repository
      #
      # @example List all worktrees in default format
      #   Git::Commands::Worktree::List.new(execution_context).call
      #
      # @example List worktrees with verbose output
      #   Git::Commands::Worktree::List.new(execution_context).call(verbose: true)
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
          flag_option %i[verbose v]
          flag_option :porcelain
          flag_option :z
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
        #     @option options [Boolean] :verbose (nil) output additional information about
        #       each worktree, including lock reason and prunable status with detail
        #
        #       Alias: :v
        #
        #     @option options [Boolean] :porcelain (nil) produce machine-readable output;
        #       format is stable across git versions regardless of user configuration
        #
        #     @option options [Boolean] :z (nil) terminate each line in porcelain output
        #       with a NUL character instead of a newline; only meaningful with :porcelain
        #
        #     @option options [String] :expire (nil) annotate missing worktrees as prunable
        #       if they are older than this time expression
        #
        #     @return [Git::CommandLineResult] the result of calling `git worktree list`
        #
        #     @raise [Git::FailedError] if git exits with a non-zero status
      end
    end
  end
end
