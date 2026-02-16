# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Branch
      # Implements the `git branch --show-current` command
      #
      # @see https://git-scm.com/docs/git-branch git-branch
      #
      # @api private
      #
      class ShowCurrent < Base
        arguments do
          literal 'branch'
          literal '--show-current'
        end

        # Execute the git branch --show-current command
        #
        # @return [Git::CommandLineResult] the result of calling `git branch --show-current`
        #
        # @raise [Git::FailedError] if git returns a non-zero exit code
        #
        def call(...) = super # rubocop:disable Lint/UselessMethodDefinition
      end
    end
  end
end
