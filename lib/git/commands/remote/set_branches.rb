# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Remote
      # Implements the `git remote set-branches` command
      #
      # Changes the list of branches tracked for the named remote.
      #
      # @see Git::Commands::Remote
      # @see https://git-scm.com/docs/git-remote git-remote
      #
      # @api private
      class SetBranches < Git::Commands::Base
        arguments do
          literal 'remote'
          literal 'set-branches'
          flag_option :add

          end_of_options

          operand :name, required: true
          operand :branch, repeatable: true, required: true
        end

        # @!method call(*, **)
        #
        #   @overload call(name, *branch, **options)
        #
        #     Execute the `git remote set-branches` command
        #
        #     @param name [String] The remote name to update
        #
        #     @param branch [Array<String>] One or more branch names or glob patterns to track
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :add (nil) Append the given branches instead of replacing them
        #
        #     @return [Git::CommandLineResult] the result of calling `git remote set-branches`
        #
        #     @raise [ArgumentError] if name is not provided or no branches are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
