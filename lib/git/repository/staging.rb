# frozen_string_literal: true

require 'git/commands/add'
require 'git/commands/reset'
require 'git/repository/internal'

module Git
  class Repository
    # Facade methods for staging-area operations: adding and resetting files
    #
    # Included by {Git::Repository}.
    #
    # @api public
    #
    module Staging
      # Option keys accepted by {#add}
      ADD_ALLOWED_OPTS = %i[all force].freeze
      private_constant :ADD_ALLOWED_OPTS

      # Update the index with the current content found in the working tree
      #
      # @overload add(paths = '.', **options)
      #
      #   @example Stage all changed files
      #     repo.add
      #
      #   @example Stage a specific file
      #     repo.add('README.md')
      #
      #   @example Stage all changes including deletions
      #     repo.add(all: true)
      #
      #   @param paths [String, Array<String>] a file or files to add (relative to
      #     the worktree root); defaults to `'.'` (all files)
      #
      #   @param options [Hash] options for the add command
      #
      #   @option options [Boolean] :all (false) add, modify, and remove index
      #     entries to match the worktree
      #
      #   @option options [Boolean] :force (false) allow adding otherwise ignored
      #     files
      #
      #   @return [String] git's stdout from the add
      #
      # @raise [ArgumentError] if unsupported options are provided
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      def add(paths = '.', **)
        Git::Repository::Internal.assert_valid_opts!(ADD_ALLOWED_OPTS, **)
        Git::Commands::Add.new(@execution_context).call(*Array(paths), **).stdout
      end

      # Option keys accepted by {#reset}
      RESET_ALLOWED_OPTS = %i[hard].freeze
      private_constant :RESET_ALLOWED_OPTS

      # Reset the current HEAD to a specified state
      #
      # @overload reset(commitish = nil, **options)
      #
      #   @example Reset the index and working tree to HEAD
      #     repo.reset
      #
      #   @example Hard reset to a specific commit
      #     repo.reset('HEAD~1', hard: true)
      #
      #   @param commitish [String, nil] the commit or tree-ish to reset to;
      #     defaults to HEAD when `nil`
      #
      #   @param options [Hash] options for the reset command
      #
      #   @option options [Boolean] :hard (false) reset the index and working
      #     tree; discards all tracked changes
      #
      #   @return [String] git's stdout from the reset
      #
      # @raise [ArgumentError] if unsupported options are provided
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      def reset(commitish = nil, **)
        Git::Repository::Internal.assert_valid_opts!(RESET_ALLOWED_OPTS, **)
        Git::Commands::Reset.new(@execution_context).call(commitish, **).stdout
      end
    end
  end
end
