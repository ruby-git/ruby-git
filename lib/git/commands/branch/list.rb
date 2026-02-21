# frozen_string_literal: true

require 'git/parsers/branch'
require 'git/commands/base'

module Git
  module Commands
    module Branch
      # Implements the `git branch --list` command
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
      class List < Base
        arguments do
          literal 'branch'
          literal '--list'
          literal "--format=#{Git::Parsers::Branch::FORMAT_STRING}"
          flag_option %i[all a]
          flag_option %i[remotes r]
          value_option :sort, inline: true, repeatable: true
          flag_or_value_option :merged
          flag_or_value_option :no_merged
          flag_or_value_option :contains
          flag_or_value_option :no_contains
          value_option :points_at
          flag_option %i[ignore_case i]
          operand :pattern, repeatable: true
        end

        # Execute the git branch --list command
        #
        # @overload call(*pattern, **options)
        #
        #   @param pattern [Array<String>] Shell wildcard patterns to filter
        #   branches
        #
        #     If multiple patterns are given, a branch is shown if it matches any of the patterns.
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :all (nil) List both local and remote branches.
        #
        #     Alias: :a
        #
        #   @option options [Boolean] :remotes (nil) List only remote-tracking
        #     branches.
        #
        #     Alias: :r
        #
        #   @option options [String, Array<String>] :sort (nil) Sort branches by the
        #     specified key(s).
        #
        #     Give an array to add multiple --sort options. Prefix each key with '-' for
        #     descending order. For example, sort: ['refname', '-committerdate'].
        #
        #   @option options [Boolean, String] :merged (nil) List only branches merged
        #     into the specified commit. Pass `true` to default to HEAD or a commit
        #     ref string to filter by that commit.
        #
        #   @option options [Boolean, String] :no_merged (nil) List only branches not
        #     merged into the specified commit. Pass `true` to default to HEAD or a
        #     commit ref string to filter by that commit.
        #
        #   @option options [Boolean, String] :contains (nil) List only branches that
        #     contain the specified commit. Pass `true` to default to HEAD or a commit
        #     ref string to filter by that commit.
        #
        #   @option options [Boolean, String] :no_contains (nil) List only branches
        #     that don't contain the specified commit. Pass `true` to default to HEAD
        #     or a commit ref string to filter by that commit.
        #
        #   @option options [String] :points_at (nil) List only branches that point
        #     at the specified object
        #
        #   @option options [Boolean] :ignore_case (nil) Sort and filter branches
        #     case insensitively.
        #
        #     Alias: :i
        #
        # @return [Git::CommandLineResult] the result of calling `git branch --list`
        #
        # @raise [ArgumentError] if unsupported options are provided
        #
        # @raise [Git::FailedError] if git returns a non-zero exit code
        #
        def call(...) = super # rubocop:disable Lint/UselessMethodDefinition
      end
    end
  end
end
