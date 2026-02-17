# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git reset` command
    #
    # This command resets the current HEAD to the specified state. It can be used to
    # unstage files, move the HEAD pointer, or reset the working directory.
    #
    # @see https://git-scm.com/docs/git-reset git-reset
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
    class Reset < Base
      arguments do
        literal 'reset'
        flag_option :hard
        flag_option :soft
        flag_option :mixed
        conflicts :hard, :soft, :mixed
        operand :commit, required: false
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
      # @return [Git::CommandLineResult] the result of calling `git reset`
      #
      # @raise [ArgumentError] if more than one of :hard, :soft, or :mixed is specified
      #
      # @raise [Git::FailedError] if the command returns a non-zero exit status
      #
      def call(...) = super # rubocop:disable Lint/UselessMethodDefinition
    end
  end
end
