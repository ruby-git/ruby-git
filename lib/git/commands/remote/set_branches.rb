# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Remote
      # `git remote set-branches` command
      #
      # Changes the list of branches tracked for the named remote. This can be used
      # to track a subset of the available remote branches after the initial setup.
      #
      # @example Set the tracked branches for a remote
      #   set_branches = Git::Commands::Remote::SetBranches.new(execution_context)
      #   set_branches.call('origin', 'main', 'develop')
      #
      # @example Append additional tracked branches without replacing existing ones
      #   set_branches = Git::Commands::Remote::SetBranches.new(execution_context)
      #   set_branches.call('origin', 'release/*', add: true)
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-remote/2.53.0
      #
      # @see Git::Commands::Remote
      #
      # @see https://git-scm.com/docs/git-remote git-remote
      #
      # @api private
      #
      class SetBranches < Git::Commands::Base
        arguments do
          literal 'remote'
          literal 'set-branches'
          flag_option :add # --add

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
        #     @param name [String] the remote name to update
        #
        #     @param branch [Array<String>] one or more branch names or glob patterns to track
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :add (nil) append the given branches instead of replacing them
        #
        #     @return [Git::CommandLineResult] the result of calling `git remote set-branches`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
