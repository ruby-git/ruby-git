# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module UpdateRef
      # Performs atomic ref updates via the `git update-ref --stdin` protocol
      #
      # Reads update/create/delete/verify instructions from stdin and applies
      # all modifications atomically — either all succeed or none do. This is
      # the transactional counterpart to the single-ref {UpdateRef::Update} and
      # {UpdateRef::Delete} commands.
      #
      # Instructions are newline-delimited by default; pass `z: true` to switch
      # to NUL-delimited format. See the
      # {https://git-scm.com/docs/git-update-ref#_stdin_mode git-update-ref}
      # documentation for the full instruction grammar.
      #
      # @example Atomically update two refs
      #   cmd = Git::Commands::UpdateRef::Batch.new(execution_context)
      #   cmd.call(
      #     'update refs/heads/main newsha oldsha',
      #     'delete refs/heads/old-branch'
      #   )
      #
      # @example NUL-delimited instructions
      #   cmd = Git::Commands::UpdateRef::Batch.new(execution_context)
      #   cmd.call("update refs/heads/main\0newsha\0oldsha", z: true)
      #
      # @see Git::Commands::UpdateRef
      #
      # @see https://git-scm.com/docs/git-update-ref git-update-ref documentation
      #
      # @api private
      #
      class Batch < Git::Commands::Base
        arguments do
          literal 'update-ref'

          # Reflog message appended to each update entry
          value_option :m

          # Overwrite refs themselves rather than following symbolic refs
          flag_option :no_deref

          # Read instructions from stdin
          literal '--stdin'

          # Use NUL-delimited input instead of newline-delimited
          flag_option :z

          # Instructions written to stdin, not argv.
          # Using skip_cli: true because these values are fed via stdin —
          # git never sees them as CLI arguments so Ruby must enforce
          # the constraint below.
          operand :instructions, repeatable: true, skip_cli: true, required: true
        end

        # @overload call(*instructions, **options)
        #
        #   Execute `git update-ref --stdin` with instructions fed via stdin
        #
        #   @param instructions [Array<String>] one or more instruction lines
        #     written to stdin of the `git update-ref` process
        #
        #     Each element is written as a separate line (or NUL-terminated
        #     record when `z: true`). The instruction format is documented in
        #     the
        #     {https://git-scm.com/docs/git-update-ref#_stdin_mode git-update-ref}
        #     man page.
        #
        #   @param options [Hash] command options
        #
        #   @option options [String] :m (nil) a reflog message for each
        #     update
        #
        #   @option options [Boolean] :no_deref (nil) overwrite refs
        #     themselves rather than following symbolic refs
        #
        #   @option options [Boolean] :z (nil) use NUL-delimited input
        #     instead of newline-delimited
        #
        #   @return [Git::CommandLineResult] the result of calling
        #     `git update-ref --stdin`
        #
        #   @raise [ArgumentError] if unsupported options are provided
        #
        #   @raise [ArgumentError] if no instructions are provided
        #
        #   @raise [Git::FailedError] if the command returns a non-zero
        #     exit status (e.g. ref lock failure or bad instruction format)
        def call(*, **)
          bound = args_definition.bind(*, **)
          delimiter = bound.z? ? "\0" : "\n"
          stdin = Array(bound.instructions).map { |i| "#{i}#{delimiter}" }.join
          with_stdin(stdin) do |reader|
            result = @execution_context.command_capturing(
              *bound, in: reader, raise_on_failure: false
            )
            validate_exit_status!(result)
            result
          end
        end
      end
    end
  end
end
