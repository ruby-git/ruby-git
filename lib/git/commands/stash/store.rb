# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Stash
      # Store a commit in the stash reflog
      #
      # This is a plumbing command used to store a given stash commit (created
      # by `git stash create`) in the stash reflog, updating refs/stash.
      #
      # This command is typically used after {Create} to actually record
      # the stash in the reflog.
      #
      # @example Store a stash commit
      #   Git::Commands::Stash::Store.new(execution_context).call('abc123def456')
      #
      # @example Store with a custom message
      #   Git::Commands::Stash::Store.new(execution_context).call('abc123def456', message: 'WIP: feature')
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-stash/2.52.0
      #
      # @see Git::Commands::Stash Git::Commands::Stash for usage examples
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      #
      # @api private
      #
      class Store < Git::Commands::Base
        arguments do
          literal 'stash'
          literal 'store'
          value_option %i[message m]  # --message (alias: :m)
          flag_option %i[quiet q]     # --quiet (alias: :q)

          end_of_options

          operand :commit, required: true
        end

        # @!method call(*, **)
        #
        #   @overload call(commit, **options)
        #
        #     Execute the `git stash store` command.
        #
        #     @param commit [String] the commit SHA to store in the stash (required)
        #
        #     @param options [Hash] command options
        #
        #     @option options [String] :message (nil) description for the reflog entry
        #
        #       Alias: :m
        #
        #     @option options [Boolean] :quiet (nil) suppress feedback messages
        #
        #       Alias: :q
        #
        #     @return [Git::CommandLineResult] the result of calling `git stash store`
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
