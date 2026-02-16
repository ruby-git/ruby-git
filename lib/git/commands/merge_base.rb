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
    #   result = merge_base.call('main', 'feature')
    #   # => #<Git::CommandLineResult ...>
    #
    # @example Find all common ancestors
    #   result = merge_base.call('main', 'feature', all: true)
    #   # => #<Git::CommandLineResult ...>
    #
    # @example Find merge base for octopus merge
    #   result = merge_base.call('main', 'branch1', 'branch2', octopus: true)
    #
    # @example Find fork point
    #   result = merge_base.call('main', 'feature', fork_point: true)
    #
    class MergeBase
      # Arguments DSL for building command-line arguments
      #
      # NOTE: The order of definitions determines the order of arguments
      # in the final command line.
      #
      ARGS = Arguments.define do
        literal 'merge-base'
        flag_option :octopus, args: '--octopus'
        flag_option :independent, args: '--independent'
        flag_option :fork_point, args: '--fork-point'
        flag_option :all, args: '--all'

        # Positional: commits to find common ancestor(s) of
        operand :commits, repeatable: true, required: true
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
      # @return [Git::CommandLineResult] the result of calling `git merge-base`
      #
      # @raise [Git::FailedError] if the command fails
      #
      def call(*, **)
        bound_args = ARGS.bind(*, **)

        @execution_context.command(*bound_args)
      end
    end
  end
end
