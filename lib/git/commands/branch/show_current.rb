# frozen_string_literal: true

module Git
  module Commands
    module Branch
      # Implements the `git branch --show-current` command
      #
      # @see https://git-scm.com/docs/git-branch git-branch
      #
      # @api private
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
        # @return [Git::CommandLineResult] the result of calling `git branch --show-current`
        #
        # @raise [Git::FailedError] if git returns a non-zero exit code
        #
        def call
          @execution_context.command('branch', '--show-current')
        end
      end
    end
  end
end
