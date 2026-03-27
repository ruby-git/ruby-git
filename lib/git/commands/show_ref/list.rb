# frozen_string_literal: true

require 'git/commands/base'
require 'git/commands/show_ref'

module Git
  module Commands
    module ShowRef
      # Standard ref listing command via `git show-ref`
      #
      # Lists refs stored in the local repository together with their associated
      # commit IDs. When no filters are given, all refs are listed. Filters can
      # narrow output to heads, tags, or refs matching a given pattern.
      #
      # An exit status of 1 is not an error — it indicates that no matching refs
      # were found. Exit status 0 means at least one match was found.
      #
      # For strict per-ref verification, use {Git::Commands::ShowRef::Verify}.
      # For stdin-based filtering, use {Git::Commands::ShowRef::ExcludeExisting}.
      # For a simple boolean existence check (git >= 2.43), use {Git::Commands::ShowRef::Exists}.
      #
      # @example List all refs
      #   cmd = Git::Commands::ShowRef::List.new(execution_context)
      #   result = cmd.call
      #   result.stdout  # => "abc1234 refs/heads/main\n..."
      #
      # @example List only tags
      #   cmd = Git::Commands::ShowRef::List.new(execution_context)
      #   result = cmd.call(tags: true)
      #
      # @example List with abbreviated SHA hashes
      #   cmd = Git::Commands::ShowRef::List.new(execution_context)
      #   result = cmd.call(hash: 7)
      #
      # @example Match a pattern
      #   cmd = Git::Commands::ShowRef::List.new(execution_context)
      #   result = cmd.call('v1.0', 'v2.0', tags: true)
      #
      # @see Git::Commands::ShowRef
      #
      # @see https://git-scm.com/docs/git-show-ref
      #
      # @api private
      #
      class List < Git::Commands::Base
        arguments do
          literal 'show-ref'

          # Include the HEAD ref even if it would normally be filtered out
          # @see https://git-scm.com/docs/git-show-ref#Documentation/git-show-ref.txt---head
          flag_option :head

          # Dereference annotated tags; outputs an additional line per tag with
          # the de-referenced object SHA followed by `^{}`
          # @see https://git-scm.com/docs/git-show-ref#Documentation/git-show-ref.txt---dereference
          flag_option %i[dereference d]

          # Show only the SHA part of the ref, optionally abbreviated to <n> hex digits;
          # pass `true` for full-length SHA, or an integer for the abbreviation length
          # @see https://git-scm.com/docs/git-show-ref#Documentation/git-show-ref.txt---hashn
          flag_or_value_option %i[hash s], inline: true

          # Abbreviate the object names to at least <n> hex digits; pass `true` to
          # use the default abbreviation length, or an integer for an explicit length
          # @see https://git-scm.com/docs/git-show-ref#Documentation/git-show-ref.txt---abbrevlength
          flag_or_value_option :abbrev, inline: true

          # Limit to refs under refs/heads/ only
          # @see https://git-scm.com/docs/git-show-ref#Documentation/git-show-ref.txt---heads
          flag_option :heads

          # Limit to refs under refs/tags/ only
          # @see https://git-scm.com/docs/git-show-ref#Documentation/git-show-ref.txt---tags
          flag_option :tags

          execution_option :timeout

          end_of_options

          # Optional glob patterns; only refs whose names contain a match are shown.
          # Patterns are matched against the full ref name (without the leading `refs/`
          # prefix on older git versions; full path on newer ones).
          operand :pattern, repeatable: true
        end

        # Exit status 1 means no refs matched; that is a normal (non-error) outcome
        allow_exit_status 0..1

        # @!method call(*pattern, **options)
        #
        #   @overload call(*pattern, **options)
        #
        #     Execute `git show-ref` to list matching refs
        #
        #     @param pattern [Array<String>] zero or more patterns to filter refs
        #
        #       When empty, all refs are listed.
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :head (nil) show the HEAD ref even when filtered
        #
        #     @option options [Boolean] :dereference (nil) dereference annotated tags,
        #       emitting an extra line per tag whose SHA points to the tagged object
        #
        #       Alias: `:d`
        #
        #     @option options [Boolean, Integer] :hash (nil) show only the SHA part of each ref
        #
        #       Pass `true` for full-length SHAs or an integer for the abbreviation length
        #       (e.g. `hash: 7`).
        #
        #       Alias: `:s`
        #
        #     @option options [Boolean, Integer] :abbrev (nil) abbreviate object names
        #
        #       Pass `true` for the default length or an integer for a specific length.
        #
        #     @option options [Boolean] :heads (nil) limit output to refs under refs/heads/
        #
        #     @option options [Boolean] :tags (nil) limit output to refs under refs/tags/
        #
        #     @option options [Numeric] :timeout (nil) abort the command after this many seconds
        #
        #     @return [Git::CommandLineResult] the result of calling `git show-ref`
        #
        #     @raise [Git::FailedError] if git exits with a status outside `0..1`
        #
      end
    end
  end
end
