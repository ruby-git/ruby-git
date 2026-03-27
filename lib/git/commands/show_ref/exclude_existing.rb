# frozen_string_literal: true

require 'git/commands/base'
require 'git/commands/show_ref'

module Git
  module Commands
    module ShowRef
      # Stdin filter mode for `git show-ref --exclude-existing`
      #
      # Reads ref names from the positional arguments, passes them to git's stdin,
      # and outputs only those refs that do NOT already exist in the local repository.
      # Useful for determining which remote refs would be new if fetched.
      #
      # Pass `exclude_existing: 'refs/heads/'` to limit filtering to refs matching
      # the given prefix pattern. By default (no pattern), all refs are evaluated.
      #
      # For standard ref listing, use {Git::Commands::ShowRef::List}.
      # For strict per-ref verification, use {Git::Commands::ShowRef::Verify}.
      # For a boolean existence check (git >= 2.43), use {Git::Commands::ShowRef::Exists}.
      #
      # @example Filter refs that do not exist locally
      #   cmd = Git::Commands::ShowRef::ExcludeExisting.new(execution_context)
      #   result = cmd.call('refs/heads/main', 'refs/heads/feature')
      #   result.stdout  # => "abc1234 refs/heads/feature\n"
      #
      # @example Limit filtering to a prefix pattern
      #   cmd = Git::Commands::ShowRef::ExcludeExisting.new(execution_context)
      #   result = cmd.call('refs/heads/main', exclude_existing: 'refs/heads/')
      #   # refs/heads/main already exists locally, so git echoes nothing
      #   result.stdout  # => ""
      #
      # @see Git::Commands::ShowRef
      #
      # @see https://git-scm.com/docs/git-show-ref git-show-ref documentation
      #
      # @api private
      #
      class ExcludeExisting < Git::Commands::Base
        arguments do
          literal 'show-ref'

          # Mode selector: pass `true` (default) to test all refs, or a pattern
          # string to restrict testing to refs whose names start with the pattern.
          # @see https://git-scm.com/docs/git-show-ref#Documentation/git-show-ref.txt---exclude-existingltpatterngt
          flag_or_value_option :exclude_existing, inline: true

          execution_option :timeout

          # Ref names to pass to stdin, one per line. Never emitted in git argv.
          operand :ref, repeatable: true, skip_cli: true
        end

        # @overload call(*ref, exclude_existing: true, **options)
        #
        #   Execute `git show-ref --exclude-existing` to filter ref names against the
        #   local repository
        #
        #   Each ref is passed to git's stdin. Git writes back only
        #   the refs that do not already exist locally.
        #
        #   @param ref [Array<String>] ref names to test
        #
        #   @param exclude_existing [true, String] filter mode selector
        #
        #     Pass `true` (default) to test all refs, or a non-empty pattern string to
        #     restrict testing to refs whose names start with the pattern
        #     (e.g. `'refs/heads/'`). Passing `false` or `nil` raises `ArgumentError`.
        #
        #   @param options [Hash] command options
        #
        #   @option options [Numeric] :timeout (nil) abort the command after this many
        #     seconds
        #
        #   @return [Git::CommandLineResult] the result of calling
        #     `git show-ref --exclude-existing`
        #
        #   @raise [Git::FailedError] if git exits with a non-zero exit status
        #
        def call(*, exclude_existing: true, **)
          unless exclude_existing == true || (exclude_existing.is_a?(String) && !exclude_existing.empty?)
            raise ArgumentError,
                  ":exclude_existing must be true or a non-empty String, got #{exclude_existing.inspect}"
          end

          bound = args_definition.bind(*, exclude_existing: exclude_existing, **)
          stdin = Array(bound.ref).map { |r| "#{r}\n" }.join
          with_stdin(stdin) { |reader| run_filter(bound, reader) }
        end

        private

        # Run the bound show-ref command, supplying ref names to git via stdin
        #
        # @param bound [Git::Commands::Arguments::Bound] bound argument list
        #
        # @param reader [IO] readable IO connected to git's stdin
        #
        # @return [Git::CommandLineResult] the result of calling
        #   `git show-ref --exclude-existing`
        #
        # @raise [Git::FailedError] if git exits with a non-zero exit status
        #
        def run_filter(bound, reader)
          result = @execution_context.command_capturing(
            *bound,
            in: reader,
            **bound.execution_options,
            raise_on_failure: false
          )
          validate_exit_status!(result)
          result
        end
      end
    end
  end
end
