# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module UpdateRef
      # Deletes a ref via `git update-ref -d`
      #
      # Removes the named ref after optionally verifying it still contains
      # `<oldvalue>`. Follows symbolic refs by default unless `no_deref: true`
      # is given.
      #
      # @example Delete a branch ref
      #   cmd = Git::Commands::UpdateRef::Delete.new(execution_context)
      #   cmd.call('refs/heads/old-branch')
      #
      # @example Delete with old-value verification
      #   cmd = Git::Commands::UpdateRef::Delete.new(execution_context)
      #   cmd.call('refs/heads/old-branch', 'expected-sha')
      #
      # @see Git::Commands::UpdateRef
      #
      # @see https://git-scm.com/docs/git-update-ref git-update-ref documentation
      #
      # @api private
      #
      class Delete < Git::Commands::Base
        arguments do
          literal 'update-ref'

          # Reflog message appended to the delete entry
          value_option :m

          # Overwrite the ref itself rather than following symbolic refs
          flag_option :no_deref

          # Delete the named ref
          literal '-d'

          end_of_options

          # The ref to delete (e.g. `refs/heads/old-branch`)
          operand :ref, required: true

          # Optional expected current value — the delete is rejected if
          # the ref does not currently point to this object
          operand :oldvalue
        end

        # @!method call(*, **)
        #
        #   @overload call(ref, oldvalue = nil, **options)
        #
        #     Execute the `git update-ref -d` command
        #
        #     @param ref [String] the ref to delete
        #       (e.g. `refs/heads/old-branch`)
        #
        #     @param oldvalue [String, nil] (nil) expected current value of
        #       the ref
        #
        #       When provided, the delete is rejected unless the ref
        #       currently points to this object.
        #
        #     @param options [Hash] command options
        #
        #     @option options [String] :m (nil) a reflog message for
        #       the deletion
        #
        #     @option options [Boolean] :no_deref (nil) overwrite the ref
        #       itself rather than following symbolic refs
        #
        #     @return [Git::CommandLineResult] the result of calling
        #       `git update-ref -d`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [ArgumentError] if the ref operand is missing
        #
        #     @raise [Git::FailedError] if the command returns a non-zero
        #       exit status
      end
    end
  end
end
