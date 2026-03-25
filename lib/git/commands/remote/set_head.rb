# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Remote
      # Implements the `git remote set-head` command
      #
      # Sets or deletes the default branch (symbolic HEAD) for the named remote.
      #
      # @see Git::Commands::Remote
      # @see https://git-scm.com/docs/git-remote git-remote
      #
      # @api private
      class SetHead < Git::Commands::Base
        arguments do
          literal 'remote'
          literal 'set-head'
          operand :name, required: true
          flag_option %i[auto a]
          flag_option %i[delete d]
          operand :branch
        end

        # @!method call(*, **)
        #
        #   @overload call(name, branch)
        #
        #     Set the remote's HEAD symbolic ref to a specific branch.
        #
        #     @param name [String] The remote name to update
        #
        #     @param branch [String] The branch to set as the remote HEAD
        #
        #     @return [Git::CommandLineResult] the result of calling `git remote set-head`
        #
        #     @raise [ArgumentError] if name is not provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
        #
        #   @overload call(name, **options)
        #
        #     Detect or delete the remote's HEAD symbolic ref.
        #
        #     @param name [String] The remote name to update
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :auto (nil) Detect the remote HEAD by querying the remote
        #
        #       Mutually exclusive with `:delete`. Alias: :a
        #
        #     @option options [Boolean] :delete (nil) Delete the configured remote HEAD symbolic ref
        #
        #       Mutually exclusive with `:auto`. Alias: :d
        #
        #     @return [Git::CommandLineResult] the result of calling `git remote set-head`
        #
        #     @raise [ArgumentError] if name is not provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
