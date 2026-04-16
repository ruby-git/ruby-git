# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git merge-base` command to find common ancestors
    #
    # Finds as good common ancestors as possible for use in a three-way merge.
    # Given two or more commits, it outputs a common ancestor reachable from
    # all of them through the parent relationship.
    #
    # @example Find merge bases of two branches
    #   merge_base = Git::Commands::MergeBase.new(execution_context)
    #   merge_base.call('main', 'feature')
    #   merge_base.call('main', 'feature', all: true)
    #   merge_base.call('main', 'b1', 'b2', octopus: true)
    #   merge_base.call('main', 'feature', fork_point: true)
    #
    # @note `arguments` block audited against
    #   https://git-scm.com/docs/git-merge-base/2.53.0
    #
    # @see https://git-scm.com/docs/git-merge-base git-merge-base
    #
    # @api private
    #
    class MergeBase < Git::Commands::Base
      arguments do
        literal 'merge-base'

        # Operation modes
        flag_option :octopus
        flag_option :independent
        flag_option :is_ancestor
        flag_option :fork_point

        # Options
        flag_option %i[all a]

        end_of_options
        operand :commit, repeatable: true, required: true
      end

      # git merge-base --fork-point returns exit code 1 when no fork point is
      # found; --is-ancestor returns exit code 1 when the first commit is not an
      # ancestor (both are valid non-error exits)
      allow_exit_status 0..1

      # @!method call(*, **)
      #
      #   @overload call(*commit, **options)
      #
      #     Execute the `git merge-base` command
      #
      #     @param commit [Array<String>] two or more commit SHAs, branch names,
      #       or refs to find common ancestor(s) of
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :octopus (false) compute best common
      #       ancestor for an n-way merge (intersection of all merge bases)
      #
      #     @option options [Boolean] :independent (false) list commits not
      #       reachable from any other; useful for finding minimal merge points
      #
      #     @option options [Boolean] :is_ancestor (false) check if the first
      #       commit is an ancestor of the second; exits 0 if true, 1 if not
      #
      #     @option options [Boolean] :fork_point (false) find the fork point
      #       where a branch diverged from another, consulting the reflog
      #
      #     @option options [Boolean] :all (false) output all merge bases instead
      #       of just one when multiple equally good bases exist
      #
      #       Alias: :a
      #
      #     @return [Git::CommandLineResult] the result of calling
      #       `git merge-base`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if git exits outside the allowed range
      #       (exit code > 1)
    end
  end
end
