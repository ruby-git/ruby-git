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
      # @see Git::Commands::Stash Git::Commands::Stash for usage examples
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      #
      # @api private
      #
      # @example Store a stash commit
      #   Git::Commands::Stash::Store.new(execution_context).call('abc123def456')
      #
      # @example Store with a custom message
      #   Git::Commands::Stash::Store.new(execution_context).call('abc123def456', message: 'WIP: feature')
      #
      class Store < Base
        arguments do
          literal 'stash'
          literal 'store'
          value_option %i[message m], inline: true
          operand :commit, required: true
        end

        # Store a commit in the stash reflog
        #
        # @overload call(commit, **options)
        #
        #   @param commit [String] the commit SHA to store in the stash (required)
        #
        #   @param options [Hash] command options
        #
        #   @option options [String] :message (nil) description for the reflog entry.
        #
        #     Alias: :m
        #
        # @return [Git::CommandLineResult] the result of calling `git stash store`
        #
        # @raise [Git::FailedError] if the commit is not a valid stash commit
        #
        def call(...) = super # rubocop:disable Lint/UselessMethodDefinition
      end
    end
  end
end
