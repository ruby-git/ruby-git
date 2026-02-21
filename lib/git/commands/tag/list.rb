# frozen_string_literal: true

require 'git/commands/base'
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
      class List < Base
        arguments do
          literal 'tag'
          literal '--list'
          literal "--format=#{Git::Parsers::Tag::FORMAT_STRING}"
          flag_or_value_option :contains
          flag_or_value_option :no_contains
          flag_or_value_option :points_at
          value_option :sort, inline: true, repeatable: true
          flag_or_value_option :merged
          flag_or_value_option :no_merged
          flag_option %i[ignore_case i]
          operand :pattern, repeatable: true
        end

        # Execute the git tag --list command
        #
        # @overload call(*pattern, **options)
        #
        #   @param pattern [Array<String>] Shell wildcard patterns to filter tags.
        #     Multiple patterns can be provided; a tag is shown if it matches any pattern.
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean, String] :contains (nil) List only tags that contain the
        #     specified commit. Pass `true` to use HEAD, or a commit reference string.
        #
        #   @option options [Boolean, String] :no_contains (nil) List only tags that don't contain
        #     the specified commit. Pass `true` to use HEAD, or a commit reference string.
        #
        #   @option options [Boolean, String] :points_at (nil) List only tags that point at the
        #     specified object. Pass `true` to use HEAD, or an object reference string.
        #
        #   @option options [String, Array<String>] :sort (nil) Sort tags by the specified
        #     key(s). Prefix `-` to sort in descending order. Common keys: 'refname',
        #     '-refname', 'creatordate', '-creatordate', 'version:refname' (for semantic
        #     version sorting).
        #
        #   @option options [Boolean, String] :merged (nil) List only tags whose commits are
        #     reachable from the specified commit. Pass `true` to use HEAD, or a commit reference string.
        #
        #   @option options [Boolean, String] :no_merged (nil) List only tags whose commits are
        #     not reachable from the specified commit. Pass `true` to use HEAD, or a commit reference string.
        #
        #   @option options [Boolean] :ignore_case (nil) Sorting and filtering tags are
        #     case insensitive. Also available as `:i`.
        #
        # @return [Git::CommandLineResult] the result of calling `git tag --list`
        #
        # @raise [Git::FailedError] if git returns a non-zero exit code
        #
        def call(...) = super # rubocop:disable Lint/UselessMethodDefinition
      end
    end
  end
end
