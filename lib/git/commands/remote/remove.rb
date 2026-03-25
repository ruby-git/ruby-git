# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Remote
      # Implements the `git remote remove` command
      #
      # Removes a remote and its associated tracking refs and configuration.
      #
      # @see Git::Commands::Remote
      # @see https://git-scm.com/docs/git-remote git-remote
      #
      # @api private
      class Remove < Git::Commands::Base
        arguments do
          literal 'remote'
          literal 'remove'
          operand :name, required: true
        end

        # @!method call(*, **)
        #
        #   @overload call(name)
        #
        #     Execute the `git remote remove` command
        #
        #     @param name [String] The remote name to remove
        #
        #     @return [Git::CommandLineResult] the result of calling `git remote remove`
        #
        #     @raise [ArgumentError] if name is not provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
