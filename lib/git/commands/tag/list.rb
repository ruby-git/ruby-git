# frozen_string_literal: true

require 'git/commands/arguments'
require 'git/tag_info'

module Git
  module Commands
    module Tag
      # Implements the `git tag --list` command
      #
      # This command lists existing tags with optional filtering and sorting.
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
          static '--list'
          inline_value :sort, multi_valued: true
          value :contains
          value :no_contains
          value :merged
          value :no_merged
          value :points_at
          positional :patterns, variadic: true
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
        #   @option options [String] :contains (nil) List only tags that contain the
        #     specified commit.
        #
        #   @option options [String] :no_contains (nil) List only tags that don't contain
        #     the specified commit.
        #
        #   @option options [String] :merged (nil) List only tags whose commits are
        #     reachable from the specified commit.
        #
        #   @option options [String] :no_merged (nil) List only tags whose commits are
        #     not reachable from the specified commit.
        #
        #   @option options [String] :points_at (nil) List only tags that point at the
        #     specified object.
        #
        # @return [Array<Git::TagInfo>] array of tag info objects
        #
        # @raise [ArgumentError] if unsupported options are provided
        #
        def call(*, **)
          args = ARGS.build(*, **)
          lines = @execution_context.command_lines('tag', *args)
          parse_tags(lines)
        end

        private

        # Parse the output lines from git tag
        #
        # @param lines [Array<String>] output lines from git tag command
        # @return [Array<Git::TagInfo>] parsed tag data
        #
        def parse_tags(lines)
          lines.map { |line| build_tag_info(line.strip) }
        end

        # Build a TagInfo from a tag name
        #
        # @note Currently only populates the name field. Other metadata fields
        #   (sha, objecttype, tagger_*, message) are set to nil. A future
        #   enhancement could use git tag --format to populate these fields.
        #
        # @param name [String] the tag name
        # @return [Git::TagInfo] tag info with name populated, other fields nil
        #
        def build_tag_info(name)
          Git::TagInfo.new(
            name: name, sha: nil, objecttype: nil,
            tagger_name: nil, tagger_email: nil, tagger_date: nil, message: nil
          )
        end
      end
    end
  end
end
