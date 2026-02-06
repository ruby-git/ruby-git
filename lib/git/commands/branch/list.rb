# frozen_string_literal: true

require 'git/branch_info'
require 'git/parsers/branch'
require 'git/commands/arguments'

module Git
  module Commands
    module Branch
      # Implements the `git branch --list` command
      #
      # This command lists existing branches with optional filtering and formatting.
      # Uses `--format` to retrieve structured data including target OID and upstream.
      #
      # Note: git may emit non-branch entries (e.g., "(HEAD detached at <ref>)" or
      # "(not a branch)") in list output. These entries are filtered out and are not
      # returned as {Git::BranchInfo} objects.
      #
      # @see https://git-scm.com/docs/git-branch git-branch
      #
      # @api private
      #
      # @example Basic branch listing
      #   list = Git::Commands::Branch::List.new(execution_context)
      #   branches = list.call
      #
      # @example List all branches (local and remote)
      #   list = Git::Commands::Branch::List.new(execution_context)
      #   all_branches = list.call(all: true)
      #
      # @example List branches containing a commit
      #   list = Git::Commands::Branch::List.new(execution_context)
      #   branches = list.call(contains: 'abc123')
      #
      # @example List branches with patterns
      #   list = Git::Commands::Branch::List.new(execution_context)
      #   feature_branches = list.call(patterns: 'feature/*')
      #
      class List
        # Arguments DSL for building command-line arguments
        #
        # NOTE: The order of definitions here determines the order of arguments
        # in the final command line.
        #
        ARGS = Arguments.define do
          literal 'branch'
          literal '--list'
          literal "--format=#{Git::Parsers::Branch::FORMAT_STRING}"
          flag_option :all, args: '-a'
          flag_option :remotes, args: '-r'
          flag_option :ignore_case
          value_option :sort, inline: true, repeatable: true
          flag_or_value_option :contains
          flag_or_value_option :no_contains
          flag_or_value_option :merged
          flag_or_value_option :no_merged
          value_option :points_at
          operand :patterns, repeatable: true
        end.freeze

        # Initialize the List command
        #
        # @param execution_context [Git::ExecutionContext, Git::Lib] the context for executing git commands
        #
        def initialize(execution_context)
          @execution_context = execution_context
        end

        # Execute the git branch --list command
        #
        # @note Detached HEAD and non-branch list entries are filtered out and will
        #   not appear in the returned array.
        #
        # @overload call(*patterns, **options)
        #
        #   @param patterns [Array<String>] Shell wildcard patterns to filter
        #   branches
        #
        #     If multiple patterns are given, a branch is shown if it matches any of the patterns.
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :all (nil) List both local and remote branches
        #   (adds -a flag)
        #
        #   @option options [Boolean] :remotes (nil) List only remote-tracking
        #   branches (adds -r flag)
        #
        #   @option options [Boolean] :ignore_case (nil) Sort and filter branches
        #   case insensitively (adds --ignore-case flag)
        #
        #   @option options [String, Array<String>] :sort (nil) Sort branches by the
        #   specified key(s)
        #
        #     Give an array to add multiple --sort options. Prefix each key with '-' for
        #     descending order. For example, sort: ['refname', '-committerdate']).
        #
        #   @option options [Boolean, String] :contains (nil) List only branches that
        #     contain the specified commit. Pass `true` to default to HEAD or a commit
        #     ref string to filter by that commit.
        #
        #   @option options [Boolean, String] :no_contains (nil) List only branches
        #     that don't contain the specified commit. Pass `true` to default to HEAD
        #     or a commit ref string to filter by that commit.
        #
        #   @option options [Boolean, String] :merged (nil) List only branches merged
        #     into the specified commit. Pass `true` to default to HEAD or a commit
        #     ref string to filter by that commit.
        #
        #   @option options [Boolean, String] :no_merged (nil) List only branches not
        #     merged into the specified commit. Pass `true` to default to HEAD or a
        #     commit ref string to filter by that commit.
        #
        #   @option options [String] :points_at (nil) List only branches that point
        #     at the specified object
        #
        # @return [Array<Git::BranchInfo>] array of branch info objects
        #
        # @raise [ArgumentError] if unsupported options are provided
        #
        def call(*, **)
          args = ARGS.bind(*, **)
          stdout = @execution_context.command(*args, raise_on_failure: false).stdout
          Git::Parsers::Branch.parse_list(stdout)
        end
      end
    end
  end
end
