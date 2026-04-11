# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Branch
      # Implements the `git branch --show-current` command
      #
      # Prints the name of the current branch. In detached HEAD state, nothing
      # is printed.
      #
      # @example Print the current branch name
      #   show_current = Git::Commands::Branch::ShowCurrent.new(execution_context)
      #   result = show_current.call
      #   puts result.stdout  # => "main\n"
      #
      # @example Check for detached HEAD state
      #   show_current = Git::Commands::Branch::ShowCurrent.new(execution_context)
      #   result = show_current.call
      #   # result.stdout is empty ("") when in detached HEAD state
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-branch/2.53.0
      #
      # @see Git::Commands::Branch
      #
      # @see https://git-scm.com/docs/git-branch git-branch
      #
      # @api private
      #
      class ShowCurrent < Git::Commands::Base
        arguments do
          literal 'branch'
          literal '--show-current'
        end

        # @!method call(*, **)
        #
        #   @overload call()
        #
        #     Execute the git branch --show-current command.
        #
        #     @return [Git::CommandLineResult] the result of calling `git branch --show-current`
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
