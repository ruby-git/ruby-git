# frozen_string_literal: true

require 'git/commands/arguments'

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
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      # @api private
      #
      # @example Store a stash commit
      #   Git::Commands::Stash::Store.new(execution_context).call('abc123def456')
      #
      # @example Store with a custom message
      #   Git::Commands::Stash::Store.new(execution_context).call('abc123def456', message: 'WIP: feature')
      #
      # @example Store quietly (suppress output)
      #   Git::Commands::Stash::Store.new(execution_context).call('abc123def456', quiet: true)
      #
      class Store
        # Arguments DSL for building command-line arguments
        ARGS = Arguments.define do
          static 'stash'
          static 'store'
          value %i[message m], inline: true
          flag %i[quiet q]
          positional :commit, required: true
        end.freeze

        # Creates a new Store command instance
        #
        # @param execution_context [Git::ExecutionContext] the execution context for running commands
        #
        def initialize(execution_context)
          @execution_context = execution_context
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
        #     Alias: :m
        #
        #   @option options [Boolean] :quiet (nil) suppress warning messages.
        #     Alias: :q
        #
        # @return [Git::CommandLineResult] the command result
        #
        # @raise [Git::FailedError] if the commit is not a valid stash commit
        #
        def call(commit, **)
          @execution_context.command(*ARGS.build(commit, **))
        end
      end
    end
  end
end
