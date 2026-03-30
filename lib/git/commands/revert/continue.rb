# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Revert
      # Implements `git revert --continue` to resume after resolving conflicts
      #
      # After the user has resolved a conflict and staged the changes, the
      # revert session can be continued with this command.
      #
      # @example Resume a revert session after resolving conflicts
      #   continue_cmd = Git::Commands::Revert::Continue.new(execution_context)
      #   continue_cmd.call
      #
      # @see Git::Commands::Revert
      #
      # @see https://git-scm.com/docs/git-revert git-revert
      #
      # @api private
      #
      class Continue < Git::Commands::Base
        arguments do
          literal 'revert'
          literal '--continue'
          flag_option :edit, negatable: true
        end

        # @!method call(*, **)
        #
        #   @overload call(**options)
        #
        #     Resume the in-progress revert after conflicts have been resolved
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :edit (nil) open the editor for the
        #       commit message
        #
        #       `true` → `--edit`, `false` → `--no-edit`. Omit to use
        #       git's default.
        #
        #     @return [Git::CommandLineResult] the result of calling
        #       `git revert --continue`
        #
        #     @raise [Git::FailedError] if no revert is in progress or conflicts
        #       remain unresolved
      end
    end
  end
end
