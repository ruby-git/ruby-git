# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module SymbolicRef
      # Deletes a symbolic ref via `git symbolic-ref --delete`
      #
      # Removes the named symbolic ref. When `quiet: true`, exit status 1
      # (non-symbolic ref) does not produce an error message.
      #
      # @example Delete a symbolic ref
      #   cmd = Git::Commands::SymbolicRef::Delete.new(execution_context)
      #   cmd.call('HEAD')
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-symbolic-ref/2.53.0
      #
      # @see Git::Commands::SymbolicRef
      #
      # @see https://git-scm.com/docs/git-symbolic-ref git-symbolic-ref documentation
      #
      # @api private
      #
      class Delete < Git::Commands::Base
        arguments do
          literal 'symbolic-ref'

          # Delete the symbolic ref
          literal '--delete'

          # Suppress error message for non-symbolic (detached) refs
          flag_option %i[quiet q]

          end_of_options

          # The symbolic ref name to delete (e.g. `HEAD`)
          operand :name, required: true
        end

        # @!method call(*, **)
        #
        #   @overload call(name, **options)
        #
        #     Execute the `git symbolic-ref --delete` command
        #
        #     @param name [String] the symbolic ref name to delete
        #       (e.g. `HEAD`)
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :quiet (false) suppress error message
        #       when the name is not a symbolic ref
        #
        #       Alias: :q
        #
        #     @return [Git::CommandLineResult] the result of calling
        #       `git symbolic-ref --delete`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [ArgumentError] if the name operand is missing
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
