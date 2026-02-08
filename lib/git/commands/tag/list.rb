# frozen_string_literal: true

require 'git/commands/arguments'
require 'git/parsers/tag'

module Git
  module Commands
    module Tag
      # Implements the `git tag --list` command
      #
      # This command lists existing tags with optional filtering and sorting.
      #
      # @see Git::Commands::Tag
      #
      # @see https://git-scm.com/docs/git-tag git-tag
      #
      # @api private
      #
      # @example Basic tag listing
      #   list = Git::Commands::Tag::List.new(execution_context)
      #   tags = list.call
      #
      # @example List tags matching a pattern
      #   list = Git::Commands::Tag::List.new(execution_context)
      #   tags = list.call('v1.*')
      #
      # @example List tags containing a commit
      #   list = Git::Commands::Tag::List.new(execution_context)
      #   tags = list.call(contains: 'abc123')
      #
      # @example List tags with multiple patterns
      #   list = Git::Commands::Tag::List.new(execution_context)
      #   tags = list.call('v1.*', 'v2.*', sort: 'version:refname')
      #
      class List
        # Arguments DSL for building command-line arguments
        #
        # NOTE: The order of definitions here determines the order of arguments
        # in the final command line.
        #
        ARGS = Arguments.define do
          literal 'tag'
          literal '--list'
          literal "--format=#{Git::Parsers::Tag::FORMAT_STRING}"
          value_option :sort, inline: true, repeatable: true
          flag_or_value_option :contains, inline: true
          flag_or_value_option :no_contains, inline: true
          flag_or_value_option :merged, inline: true
          flag_or_value_option :no_merged, inline: true
          flag_or_value_option :points_at, inline: true
          flag_option %i[ignore_case i]
          operand :patterns, repeatable: true
        end.freeze

        # Initialize the List command
        #
        # @param execution_context [Git::ExecutionContext, Git::Lib] the context for executing git commands
        #
        def initialize(execution_context)
          @execution_context = execution_context
        end

        # Execute the git tag --list command
        #
        # @overload call(*patterns, **options)
        #
        #   @param patterns [Array<String>] Shell wildcard patterns to filter tags.
        #     Multiple patterns can be provided; a tag is shown if it matches any pattern.
        #
        #   @param options [Hash] command options
        #
        #   @option options [String, Array<String>] :sort (nil) Sort tags by the specified
        #     key(s). Prefix `-` to sort in descending order. Common keys: 'refname',
        #     '-refname', 'creatordate', '-creatordate', 'version:refname' (for semantic
        #     version sorting).
        #
        #   @option options [Boolean, String] :contains (nil) List only tags that contain the
        #     specified commit. Pass `true` to use HEAD, or a commit reference string.
        #
        #   @option options [Boolean, String] :no_contains (nil) List only tags that don't contain
        #     the specified commit. Pass `true` to use HEAD, or a commit reference string.
        #
        #   @option options [Boolean, String] :merged (nil) List only tags whose commits are
        #     reachable from the specified commit. Pass `true` to use HEAD, or a commit reference string.
        #
        #   @option options [Boolean, String] :no_merged (nil) List only tags whose commits are
        #     not reachable from the specified commit. Pass `true` to use HEAD, or a commit reference string.
        #
        #   @option options [Boolean, String] :points_at (nil) List only tags that point at the
        #     specified object. Pass `true` to use HEAD, or an object reference string.
        #
        #   @option options [Boolean] :ignore_case (nil) Sorting and filtering tags are
        #     case insensitive. Also available as `:i`.
        #
        # @return [Git::CommandLineResult] the result of calling `git tag --list`
        #
        # @raise [Git::FailedError] if git returns a non-zero exit code
        #
        def call(*, **)
          bound_args = ARGS.bind(*, **)

          @execution_context.command(*bound_args)
        end
      end
    end
  end
end
