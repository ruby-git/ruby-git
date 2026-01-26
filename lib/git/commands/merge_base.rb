# frozen_string_literal: true

require 'git/commands/arguments'

module Git
  module Commands
    # Implements the `git merge-base` command to find common ancestors
    #
    # This command finds as good common ancestors as possible for a merge.
    # Given two commits, it outputs a common ancestor that is reachable from
    # both commits through the parent relationship.
    #
    # @see https://git-scm.com/docs/git-merge-base git-merge-base
    #
    # @api private
    #
    # @example Find merge base of two branches
    #   merge_base = Git::Commands::MergeBase.new(execution_context)
    #   shas = merge_base.call('main', 'feature')
    #   # => ['abc123def456...']
    #
    # @example Find all common ancestors
    #   shas = merge_base.call('main', 'feature', all: true)
    #   # => ['sha1', 'sha2']
    #
    # @example Find merge base for octopus merge
    #   shas = merge_base.call('main', 'branch1', 'branch2', octopus: true)
    #
    # @example Find fork point
    #   shas = merge_base.call('main', 'feature', fork_point: true)
    #
    class MergeBase
      # Arguments DSL for building command-line arguments
      #
      # NOTE: The order of definitions determines the order of arguments
      # in the final command line.
      #
      ARGS = Arguments.define do
        static 'merge-base'
        flag :octopus, args: '--octopus'
        flag :independent, args: '--independent'
        flag :fork_point, args: '--fork-point'
        flag :all, args: '--all'

        # Positional: commits to find common ancestor(s) of
        positional :commits, variadic: true, required: true
      end.freeze

      # Initialize the MergeBase command
      #
      # @param execution_context [Git::ExecutionContext, Git::Lib] the context for executing git commands
      #
      def initialize(execution_context)
        @execution_context = execution_context
      end

      # Execute the git merge-base command
      #
      # @overload call(*commits, **options)
      #
      #   @param commits [Array<String>] Two or more commit SHAs, branch names,
      #     or refs to find common ancestor(s) of
      #
      #   @param options [Hash] command options
      #
      #   @option options [Boolean] :octopus (nil) Compute best common ancestor
      #     for an n-way merge (intersection of all merge bases)
      #
      #   @option options [Boolean] :independent (nil) List commits not reachable
      #     from any other (useful for finding branch tips)
      #
      #   @option options [Boolean] :fork_point (nil) Find the fork point where
      #     a branch diverged from another
      #
      #   @option options [Boolean] :all (nil) Output all merge bases instead of
      #     just one (when multiple equally good bases exist)
      #
      # @return [Array<String>] array of commit SHA strings (common ancestors)
      #
      # @raise [Git::FailedError] if the command fails
      #
      def call(*, **)
        args = ARGS.build(*, **)
        output = @execution_context.command(*args)
        parse_output(output)
      end

      private

      # Parse the command output into an array of SHAs
      #
      # @param output [String] the raw command output
      # @return [Array<String>] array of commit SHAs
      #
      def parse_output(output)
        output.lines.map(&:strip).reject(&:empty?)
      end
    end
  end
end
