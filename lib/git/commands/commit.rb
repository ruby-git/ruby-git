# frozen_string_literal: true

require 'git/commands/base'

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
    class Commit < Base
      arguments do
        literal 'commit'
        # Always suppress editor (non-interactive use)
        literal '--no-edit'
        flag_option %i[all a]
        flag_option :amend
        value_option %i[message m], inline: true, allow_empty: true
        flag_option :allow_empty
        flag_option :allow_empty_message
        flag_option :no_verify
        value_option :author, inline: true
        value_option :date, inline: true, type: String
        flag_or_value_option %i[gpg_sign S], negatable: true, inline: true
      end

      # Execute the git commit command
      #
      # @overload call(**options)
      #
      #   @param options [Hash] command options
      #
      #   @option options [Boolean] :all (nil) Automatically stage all modified and deleted files
      #     before committing.
      #     Alias: :a
      #
      #   @option options [Boolean] :amend (nil) Amend the previous commit instead of creating a new one
      #
      #   @option options [String] :message (nil) The commit message.
      #     Alias: :m
      #
      #   @option options [Boolean] :allow_empty (nil) Allow creating a commit with no changes
      #
      #   @option options [Boolean] :allow_empty_message (nil) Allow creating a commit with an empty message
      #
      #   @option options [Boolean] :no_verify (nil) Bypass the pre-commit and commit-msg hooks
      #
      #   @option options [String] :author (nil) Override the commit author in the format 'Name <email>'
      #
      #   @option options [String] :date (nil) Override the author date. Must be a string in a format
      #     that git understands (e.g., '2023-01-15T10:30:00', 'now', 'yesterday')
      #
      #   @option options [Boolean, String, false] :gpg_sign (nil) GPG-sign the commit. When true, uses the
      #     default key. When a string, uses the specified key ID. When false, adds --no-gpg-sign
      #     to override any commit.gpgsign configuration.
      #     Alias: :S
      #
      # @return [Git::CommandLineResult] the result of calling `git commit`
      #
      # @raise [ArgumentError] if unsupported options are provided
      #
      # @raise [ArgumentError] if :date is not a String
      #
      # @raise [Git::FailedError] if the command returns a non-zero exit status
      #
      def call(...) = super # rubocop:disable Lint/UselessMethodDefinition
    end
  end
end
