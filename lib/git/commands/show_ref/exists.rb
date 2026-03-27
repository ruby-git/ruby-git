# frozen_string_literal: true

require 'git/commands/base'
require 'git/commands/show_ref'

module Git
  module Commands
    module ShowRef
      # Checks whether a single ref exists via `git show-ref --exists`
      #
      # Returns without raising for three exit-status outcomes:
      #
      # - **exit 0** — the ref exists in the local repository
      # - **exit 2** — the ref does not exist (a normal result for an existence check)
      # - **exit 1** — a lookup error occurred (e.g. malformed ref name)
      #
      # Callers inspect `result.status.exitstatus` to distinguish the three states.
      # Unlike {ShowRef::Verify}, this mode never prints any output.
      #
      # For standard ref listing, use {ShowRef::List}.
      # For strict per-ref verification with output, use {ShowRef::Verify}.
      # For stdin-based filtering, use {ShowRef::ExcludeExisting}.
      #
      # @example Check whether a branch exists
      #   cmd = Git::Commands::ShowRef::Exists.new(execution_context)
      #   result = cmd.call('refs/heads/main')
      #   result.status.exitstatus  # => 0 (exists) or 2 (not found)
      #
      # @note Requires git 2.43 or later
      #
      #   Earlier versions do not recognise the `--exists` flag and will exit
      #   non-zero with an "unknown option" error.
      #
      # @see Git::Commands::ShowRef
      #
      # @see https://git-scm.com/docs/git-show-ref git-show-ref documentation
      #
      # @api private
      #
      class Exists < Git::Commands::Base
        arguments do
          literal 'show-ref'
          literal '--exists'
          execution_option :timeout
          operand :ref, required: true
        end

        # Exit status 0 = ref found; 2 = ref not found (expected); 1 = lookup error.
        # All three are valid results — callers check exitstatus to distinguish them.
        allow_exit_status 0..2

        # @!method call(*, **)
        #
        #   @overload call(ref, **options)
        #
        #     Execute `git show-ref --exists` to check whether a ref exists
        #
        #     @param ref [String] the fully-qualified ref name to check
        #       (e.g. `"refs/heads/main"`)
        #
        #     @param options [Hash] command options
        #
        #     @option options [Numeric] :timeout (nil) abort the command after this many
        #       seconds
        #
        #     @return [Git::CommandLineResult] the result of calling
        #       `git show-ref --exists`
        #
        #     @raise [ArgumentError] if no ref is provided
        #
        #     @raise [Git::FailedError] if git exits with a status outside `0..2`
        #
      end
    end
  end
end
