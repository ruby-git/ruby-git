# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module UpdateRef
      # Updates a ref to point to a new object via `git update-ref`
      #
      # Stores `<newvalue>` in `<ref>`, optionally verifying that the current
      # value matches `<oldvalue>` before performing the update. Follows
      # symbolic refs by default unless `no_deref: true` is given.
      #
      # @example Update a branch ref
      #   cmd = Git::Commands::UpdateRef::Update.new(execution_context)
      #   cmd.call('refs/heads/main', 'abc1234')
      #
      # @example Update with old-value verification
      #   cmd = Git::Commands::UpdateRef::Update.new(execution_context)
      #   cmd.call('refs/heads/main', 'newsha', 'oldsha')
      #
      # @example Update with a reflog message
      #   cmd = Git::Commands::UpdateRef::Update.new(execution_context)
      #   cmd.call('refs/heads/main', 'abc1234', m: 'reset to upstream')
      #
      # @see Git::Commands::UpdateRef
      #
      # @see https://git-scm.com/docs/git-update-ref git-update-ref documentation
      #
      # @api private
      #
      class Update < Git::Commands::Base
        arguments do
          literal 'update-ref'

          # Reflog message appended to the update entry
          value_option :m

          # Overwrite the ref itself rather than following symbolic refs
          flag_option :no_deref

          # Create a reflog for the ref even if one would not ordinarily
          # be created
          flag_option :create_reflog

          end_of_options

          # The ref to update (e.g. `refs/heads/main`)
          operand :ref, required: true

          # The new object name to store in the ref
          operand :newvalue, required: true

          # Optional expected current value — the update is rejected if
          # the ref does not currently point to this object
          operand :oldvalue
        end

        # @!method call(*, **)
        #
        #   @overload call(ref, newvalue, oldvalue = nil, **options)
        #
        #     Execute the `git update-ref` command
        #
        #     @param ref [String] the ref to update (e.g. `refs/heads/main`)
        #
        #     @param newvalue [String] the new object name to store
        #
        #     @param oldvalue [String, nil] (nil) expected current value of
        #       the ref
        #
        #       When provided, the update is rejected unless the ref
        #       currently points to this object. Use 40 `"0"` characters
        #       or an empty string to assert the ref does not yet exist.
        #
        #     @param options [Hash] command options
        #
        #     @option options [String] :m (nil) a reflog message for
        #       the update
        #
        #     @option options [Boolean] :no_deref (nil) overwrite the ref
        #       itself rather than following symbolic refs
        #
        #     @option options [Boolean] :create_reflog (nil) create a reflog
        #       even if one would not ordinarily be created
        #
        #     @return [Git::CommandLineResult] the result of calling
        #       `git update-ref`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [ArgumentError] if the ref or newvalue operand is
        #       missing
        #
        #     @raise [Git::FailedError] if the command returns a non-zero
        #       exit status
      end
    end
  end
end
