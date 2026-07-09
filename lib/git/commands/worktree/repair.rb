# frozen_string_literal: true

require 'git/commands/worktree/management_base'

module Git
  module Commands
    module Worktree
      # Repairs worktree administrative files
      #
      # Resolves broken links between the repository and one or more linked
      # worktrees. Useful after a worktree directory is moved manually.
      #
      # @example Repair all registered worktrees
      #   Git::Commands::Worktree::Repair.new(execution_context).call
      #
      # @example Repair specific moved worktrees
      #   Git::Commands::Worktree::Repair.new(execution_context).call('/tmp/moved1', '/tmp/moved2')
      #
      # @note `arguments` block audited against
      #   https://git-scm.com/docs/git-worktree/2.54.0
      #
      # @see Git::Commands::Worktree Git::Commands::Worktree for the full sub-command list
      #
      # @see https://git-scm.com/docs/git-worktree git-worktree documentation
      #
      # @api private
      #
      class Repair < ManagementBase
        arguments do
          literal 'worktree'
          literal 'repair'
          flag_option :relative_paths, negatable: true
          end_of_options
          operand :path, repeatable: true
        end

        # git worktree repair was introduced in git 2.29.0
        requires_git_version '2.29.0'

        # @!method call(*)
        #
        #   @overload call(*path, **options)
        #
        #     Repair worktree administrative files
        #
        #     @param path [Array<String>] paths to specific worktrees to repair
        #
        #       When omitted, all registered worktrees are repaired.
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean, nil] :relative_paths (nil) link worktrees using
        #       relative paths (`--relative-paths`)
        #
        #       Overrides the `worktree.useRelativePaths` config option.
        #
        #     @option options [Boolean, nil] :no_relative_paths (nil) use absolute paths
        #       for worktree links (`--no-relative-paths`)
        #
        #       Overrides the `worktree.useRelativePaths` config option. Also causes
        #       repair to update linking files if there is an absolute/relative
        #       mismatch, even if the links are already correct.
        #
        #     @return [Git::CommandLine::Result] the result of calling `git worktree repair`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
        #
        #     @raise [Git::VersionError] if git version is below 2.29.0
        #
        #     @api public
      end
    end
  end
end
