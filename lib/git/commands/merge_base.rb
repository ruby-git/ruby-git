# frozen_string_literal: true

require 'git/commands/base'

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
    class MergeBase < Git::Commands::Base
      arguments do
        literal 'merge-base'
        flag_option %i[all a]
        flag_option :octopus
        flag_option :independent
        flag_option :fork_point

        # Positional: commits to find common ancestor(s) of
        operand :commit, repeatable: true, required: true
        conflicts :octopus, :independent, :fork_point
        conflicts :all, :independent
        conflicts :all, :fork_point
      end

      # git merge-base --fork-point returns exit code 1 when no fork point is found (not an error)
      allow_exit_status 0..1

      # @!method call(*, **)
      #
      #   Execute the git merge-base command
      #
      #   @overload call(*commit, **options)
      #
      #     @param commit [Array<String>] Two or more commit SHAs, branch names,
      #       or refs to find common ancestor(s) of
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :all (nil) Output all merge bases instead of
      #       just one (when multiple equally good bases exist).
      #       Alias: :a
      #
      #     @option options [Boolean] :octopus (nil) Compute best common ancestor
      #       for an n-way merge (intersection of all merge bases)
      #
      #     @option options [Boolean] :independent (nil) List commits not reachable
      #       from any other (useful for finding branch tips)
      #
      #     @option options [Boolean] :fork_point (nil) Find the fork point where
      #       a branch diverged from another
      #
      #     @return [Git::CommandLineResult] the result of calling `git merge-base`
      #
      #     @raise [Git::FailedError] if git returns an exit code > 1
    end
  end
end
