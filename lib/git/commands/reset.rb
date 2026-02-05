# frozen_string_literal: true

require 'git/commands/arguments'

module Git
  module Commands
    # Implements the `git reset` command
    #
    # This command resets the current HEAD to the specified state. It can be used to
    # unstage files, move the HEAD pointer, or reset the working directory.
    #
    # @api private
    #
    # @example Reset to HEAD (default)
    #   reset = Git::Commands::Reset.new(execution_context)
    #   reset.call
    #
    # @example Reset to a specific commit
    #   reset.call('HEAD~1')
    #   reset.call('abc123def')
    #
    # @example Hard reset (resets index and working directory)
    #   reset.call('HEAD~1', hard: true)
    #
    # @example Soft reset (keeps changes staged)
    #   reset.call('HEAD~1', soft: true)
    #
    # @example Mixed reset (keeps changes unstaged)
    #   reset.call('HEAD~1', mixed: true)
    #
    class Reset
      # Arguments DSL for building command-line arguments
      ARGS = Arguments.define do
        literal 'reset'
        flag_option :hard
        flag_option :soft
        flag_option :mixed
        conflicts :hard, :soft, :mixed
        operand :commit, required: false
      end.freeze

      # Initialize the Reset command
      #
      # @param execution_context [Git::ExecutionContext, Git::Lib] the context for executing git commands
      #
      def initialize(execution_context)
        @execution_context = execution_context
      end

      # Execute the git reset command
      #
      # @overload call(commit = nil, **options)
      #
      #   @param commit [String, nil] the commit to reset to (defaults to HEAD if not specified)
      #
      #   @param options [Hash] command options
      #
      #   @option options [Boolean] :hard (nil) reset the index and working tree. Any changes to tracked
      #     files in the working tree since the commit are discarded
      #
      #   @option options [Boolean] :soft (nil) does not touch the index file or the working tree at all,
      #     but resets the head to the commit
      #
      #   @option options [Boolean] :mixed (nil) resets the index but not the working tree (i.e., the
      #     changed files are preserved but not marked for commit)
      #
      # @raise [ArgumentError] if more than one of :hard, :soft, or :mixed is specified
      #
      # @return [Git::CommandLineResult] the result of the command
      #
      def call(*, **)
        args = ARGS.bind(*, **)
        @execution_context.command(*args)
      end
    end
  end
end
