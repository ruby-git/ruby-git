# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Remote
      # `git remote remove` command
      #
      # Removes a remote and its associated tracking refs and configuration.
      #
      # @example Remove a remote
      #   remove = Git::Commands::Remote::Remove.new(execution_context)
      #   remove.call('origin')
      #
      # @example Remove a remote with a name that looks like a flag
      #   remove = Git::Commands::Remote::Remove.new(execution_context)
      #   remove.call('-weirdremote')
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-remote/2.53.0
      #
      # @see Git::Commands::Remote
      #
      # @see https://git-scm.com/docs/git-remote git-remote
      #
      # @api private
      #
      class Remove < Git::Commands::Base
        arguments do
          literal 'remote'
          literal 'remove'

          end_of_options

          operand :name, required: true
        end

        # @!method call(*, **)
        #
        #   @overload call(name)
        #
        #     Execute the `git remote remove` command
        #
        #     @param name [String] the remote name to remove
        #
        #     @return [Git::CommandLineResult] the result of calling `git remote remove`
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
