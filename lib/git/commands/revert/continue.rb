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
      # @note `arguments` block audited against https://git-scm.com/docs/git-revert/2.53.0
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
          flag_option %i[edit e], negatable: true
        end

        # @!method call(*, **)
        #
        #   @overload call(**options)
        #
        #     Resume the in-progress revert after conflicts have been resolved
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :edit (false) open the editor for the
        #       commit message (`--edit`)
        #
        #       Alias: `:e`
        #
        #     @option options [Boolean] :no_edit (false) suppress the editor for
        #       the commit message (`--no-edit`)
        #
        #     @return [Git::CommandLineResult] the result of calling
        #       `git revert --continue`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
