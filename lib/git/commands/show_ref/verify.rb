# frozen_string_literal: true

require 'git/commands/base'
require 'git/commands/show_ref'

module Git
  module Commands
    module ShowRef
      # Strict per-ref verification command via `git show-ref --verify`
      #
      # Verifies that refs exist by their full canonical name (e.g.
      # `refs/heads/main`, `refs/tags/v1.0`). Unlike {ShowRef::List}, partial
      # name matching is not performed. Every named ref must start with `refs/`
      # (or be `HEAD`); anything else will cause git to exit non-zero.
      #
      # When a ref cannot be resolved, git exits 1 and this class raises
      # {Git::FailedError}. This strict behaviour makes the class suitable for
      # validating that refs are fully qualified.
      #
      # For pattern-based listing, use {ShowRef::List}.
      # For stdin-based filtering, use {ShowRef::ExcludeExisting}.
      # For a silent boolean check (git >= 2.43), use {ShowRef::Exists}.
      #
      # @example Verify a single ref
      #   cmd = Git::Commands::ShowRef::Verify.new(execution_context)
      #   result = cmd.call('refs/heads/main')
      #   result.stdout  # => "abc1234 refs/heads/main\n"
      #
      # @example Verify with hash-only output
      #   cmd = Git::Commands::ShowRef::Verify.new(execution_context)
      #   result = cmd.call('refs/heads/main', hash: true)
      #   result.stdout  # => "abc1234\n"
      #
      # @example Silent existence check
      #   cmd = Git::Commands::ShowRef::Verify.new(execution_context)
      #   cmd.call('refs/heads/main', quiet: true)  # raises FailedError if not found
      #
      # @see Git::Commands::ShowRef
      #
      # @see https://git-scm.com/docs/git-show-ref git-show-ref documentation
      #
      # @api private
      #
      class Verify < Git::Commands::Base
        arguments do
          literal 'show-ref'
          literal '--verify'

          # Suppress output; useful when you only care whether the ref exists
          # @see https://git-scm.com/docs/git-show-ref#Documentation/git-show-ref.txt---quiet
          flag_option %i[quiet q]

          # Dereference annotated tags; emit an extra line per tag with SHA^{}
          # @see https://git-scm.com/docs/git-show-ref#Documentation/git-show-ref.txt---dereference
          flag_option %i[dereference d]

          # Show only the SHA; pass `true` for full-length or an integer for abbreviated length
          # @see https://git-scm.com/docs/git-show-ref#Documentation/git-show-ref.txt---hashn
          flag_or_value_option %i[hash s], inline: true

          # Abbreviate object names; pass `true` for default or integer for explicit length
          # @see https://git-scm.com/docs/git-show-ref#Documentation/git-show-ref.txt---abbrevlength
          flag_or_value_option :abbrev, inline: true

          execution_option :timeout

          end_of_options

          # One or more fully-qualified ref names to verify (e.g. `refs/heads/main`)
          operand :ref, repeatable: true, required: true
        end

        # @!method call(*ref, **options)
        #
        #   @overload call(*ref, **options)
        #
        #     Execute `git show-ref --verify` to verify refs by their full name
        #
        #     @param ref [Array<String>] one or more fully-qualified ref names
        #
        #       Each name must begin with `refs/` (or be `HEAD`). At least one is required.
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :quiet (nil) suppress all output
        #
        #       Useful when you only care whether the ref exists.
        #
        #       Alias: `:q`
        #
        #     @option options [Boolean] :dereference (nil) dereference annotated tags,
        #       emitting an extra `^{}` line per tag
        #
        #       Alias: `:d`
        #
        #     @option options [Boolean, Integer] :hash (nil) show only the SHA part
        #
        #       Pass `true` for full-length SHAs or an integer for abbreviation length.
        #
        #       Alias: `:s`
        #
        #     @option options [Boolean, Integer] :abbrev (nil) abbreviate object names
        #
        #       Pass `true` for the default length or an integer for a specific length.
        #
        #     @option options [Numeric] :timeout (nil) abort the command after this many
        #       seconds
        #
        #     @return [Git::CommandLineResult] the result of calling `git show-ref --verify`
        #
        #     @raise [ArgumentError] if no ref names are provided
        #
        #     @raise [Git::FailedError] if any ref cannot be resolved (exit status 1)
        #
      end
    end
  end
end
