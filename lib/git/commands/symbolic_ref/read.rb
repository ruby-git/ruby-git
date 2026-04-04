# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module SymbolicRef
      # Reads the target of a symbolic ref via `git symbolic-ref`
      #
      # Given one argument, reads which branch head the given symbolic ref
      # refers to and outputs its path, relative to the `.git/` directory.
      #
      # Exits with status 0 if the contents were printed correctly, or
      # status 1 if the requested name is not a symbolic ref (e.g. a
      # detached HEAD). When `quiet: true`, exit status 1 is silent
      # (no error message on stderr).
      #
      # @example Read current HEAD
      #   cmd = Git::Commands::SymbolicRef::Read.new(execution_context)
      #   result = cmd.call('HEAD')
      #   result.stdout  # => "refs/heads/main"
      #
      # @example Read HEAD with shortened output
      #   cmd = Git::Commands::SymbolicRef::Read.new(execution_context)
      #   result = cmd.call('HEAD', short: true)
      #   result.stdout  # => "main"
      #
      # @see Git::Commands::SymbolicRef
      #
      # @see https://git-scm.com/docs/git-symbolic-ref git-symbolic-ref documentation
      #
      # @api private
      #
      class Read < Git::Commands::Base
        arguments do
          literal 'symbolic-ref'

          # Suppress error message for non-symbolic (detached) refs
          flag_option %i[quiet q]

          # Shorten the ref output (e.g. `refs/heads/main` → `main`)
          flag_option :short

          end_of_options

          # The symbolic ref name to read (e.g. `HEAD`)
          operand :name, required: true
        end

        # Exit status 1 indicates the name is not a symbolic ref
        # (e.g. detached HEAD) — this is not an error
        allow_exit_status 0..1

        # @!method call(*, **)
        #
        #   @overload call(name, **options)
        #
        #     Execute the `git symbolic-ref` command to read a symbolic ref
        #
        #     @param name [String] the symbolic ref name to read
        #       (e.g. `HEAD`)
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :quiet (nil) suppress error message
        #       when the name is not a symbolic ref
        #
        #       Alias: :q
        #
        #     @option options [Boolean] :short (nil) shorten the ref output
        #       (e.g. `refs/heads/main` → `main`)
        #
        #     @return [Git::CommandLineResult] the result of calling
        #       `git symbolic-ref`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [ArgumentError] if the name operand is missing
        #
        #     @raise [Git::FailedError] if git exits with status >= 2
      end
    end
  end
end
