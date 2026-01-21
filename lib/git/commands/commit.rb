# frozen_string_literal: true

require 'git/commands/arguments'

module Git
  module Commands
    # Implements the `git commit` command
    #
    # This command records changes to the repository by creating a new commit
    # with the staged changes.
    #
    # @see https://git-scm.com/docs/git-commit git-commit
    #
    # @api private
    #
    # @example Basic usage
    #   commit = Git::Commands::Commit.new(execution_context)
    #   commit.call(message: 'Initial commit')
    #
    # @example With options
    #   commit = Git::Commands::Commit.new(execution_context)
    #   commit.call(message: 'Add feature', all: true, author: 'Jane <jane@example.com>')
    #
    # @example Amending the previous commit
    #   commit = Git::Commands::Commit.new(execution_context)
    #   commit.call(amend: true)
    #
    class Commit
      # Arguments DSL for building command-line arguments
      #
      # NOTE: The order of definitions here determines the order of arguments
      # in the final command line. This order matches the original COMMIT_OPTION_MAP
      # for backward compatibility with existing tests.
      #
      ARGS = Arguments.define do
        flag %i[all add_all]
        flag :allow_empty
        flag :no_verify
        flag :allow_empty_message
        inline_value :author
        inline_value :message, allow_empty: true
        inline_value :date, type: String
        flag :amend, args: ['--amend', '--no-edit']
        negatable_flag_or_inline_value :gpg_sign
      end.freeze

      # Initialize the Commit command
      #
      # @param execution_context [Git::ExecutionContext, Git::Lib] the context for executing git commands
      #
      def initialize(execution_context)
        @execution_context = execution_context
      end

      # Execute the git commit command
      #
      # @overload call(message: nil, all: nil, add_all: nil, allow_empty: nil,
      #   allow_empty_message: nil, amend: nil, author: nil, date: nil,
      #   no_verify: nil, gpg_sign: nil)
      #
      #   @param message [String] The commit message
      #
      #   @param all [Boolean] Automatically stage all modified and deleted files
      #     before committing (alias: add_all)
      #
      #   @param add_all [Boolean] Alias for :all
      #
      #   @param allow_empty [Boolean] Allow creating a commit with no changes
      #
      #   @param allow_empty_message [Boolean] Allow creating a commit with an empty message
      #
      #   @param amend [Boolean] Amend the previous commit instead of creating a new one.
      #     When true, --no-edit is also added to prevent opening an editor.
      #
      #   @param author [String] Override the commit author in the format 'Name <email>'
      #
      #   @param date [String] Override the author date. Must be a string in a format
      #     that git understands (e.g., '2023-01-15T10:30:00', 'now', 'yesterday')
      #
      #   @param no_verify [Boolean] Bypass the pre-commit and commit-msg hooks
      #
      #   @param gpg_sign [Boolean, String, false] GPG-sign the commit. When true, uses the
      #     default key. When a string, uses the specified key ID. When false, adds --no-gpg-sign
      #     to override any commit.gpgsign configuration.
      #
      # @return [String] the command output
      #
      # @raise [ArgumentError] if unsupported options are provided
      # @raise [ArgumentError] if :date is not a String
      #
      def call(**)
        args = ARGS.build(**)
        @execution_context.command('commit', *args)
      end
    end
  end
end
