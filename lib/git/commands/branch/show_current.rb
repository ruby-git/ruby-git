# frozen_string_literal: true

require 'git/commands/branch/list'
require 'git/detached_head_info'

module Git
  module Commands
    module Branch
      # Implements the `git branch --show-current` command
      #
      # This command prints the name of the current branch. In detached HEAD state,
      # returns a {Git::DetachedHeadInfo} object with the commit SHA.
      #
      # @see https://git-scm.com/docs/git-branch git-branch
      #
      # @api private
      #
      # @example Get the current branch
      #   show_current = Git::Commands::Branch::ShowCurrent.new(execution_context)
      #   result = show_current.call
      #   result.short_name  #=> 'main'
      #   result.detached?   #=> false
      #
      # @example Detached HEAD state
      #   show_current = Git::Commands::Branch::ShowCurrent.new(execution_context)
      #   result = show_current.call
      #   result.short_name  #=> 'HEAD'
      #   result.detached?   #=> true
      #   result.target_oid  #=> 'abc123...'
      #
      class ShowCurrent
        # Initialize the ShowCurrent command
        #
        # @param execution_context [Git::ExecutionContext, Git::Lib] the context for executing git commands
        #
        def initialize(execution_context)
          @execution_context = execution_context
        end

        # Execute the git branch --show-current command
        #
        # @return [Git::BranchInfo, Git::DetachedHeadInfo] the current branch info,
        #   or DetachedHeadInfo if in detached HEAD state
        #
        def call
          result = @execution_context.command('branch', '--show-current')
          branch_name = result.stdout.strip

          # Empty output means detached HEAD state
          return detached_head_info if branch_name.empty?

          branch_info_for(branch_name)
        end

        private

        # Look up BranchInfo for the named branch, or create one for unborn branches
        #
        # @param branch_name [String] the branch name
        # @return [Git::BranchInfo]
        def branch_info_for(branch_name)
          # Look up full BranchInfo for the current branch
          # This may return nil for an unborn branch (no commits yet)
          branch_info = Git::Commands::Branch::List.new(@execution_context).call(branch_name).first

          # For unborn branches, create a minimal BranchInfo
          branch_info || unborn_branch_info(branch_name)
        end

        # Create a BranchInfo for an unborn branch (no commits yet)
        #
        # @param branch_name [String] the branch name
        # @return [Git::BranchInfo]
        def unborn_branch_info(branch_name)
          Git::BranchInfo.new(
            refname: branch_name,
            target_oid: nil,
            current: true,
            worktree: false,
            symref: nil,
            upstream: nil
          )
        end

        # Create a DetachedHeadInfo with the current HEAD commit SHA
        #
        # @return [Git::DetachedHeadInfo]
        def detached_head_info
          sha = @execution_context.command('rev-parse', 'HEAD').stdout.strip
          Git::DetachedHeadInfo.new(target_oid: sha)
        end
      end
    end
  end
end
