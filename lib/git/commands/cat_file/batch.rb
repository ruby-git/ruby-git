# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module CatFile
      # Queries one or more git objects via the batch stdin streaming protocol
      #
      # Accepts object names (or commands) written to stdin. Three output modes are
      # available, selected by passing exactly one of `batch:`, `batch_check:`, or
      # `batch_command:` as a keyword argument:
      #
      # - **`batch: true`** (`--batch`) — for each named object, write a header line
      #   `<sha> <type> <size>` followed by the raw content bytes and a newline
      #   separator; missing objects are reported inline as `<name> missing`
      # - **`batch_check: true`** (`--batch-check`) — for each named object, write
      #   one metadata line `<sha> <type> <size>`; missing objects as `<name> missing`
      # - **`batch_command: true`** (`--batch-command`) — enter command-dispatch mode;
      #   stdin carries named verbs (`contents <object>`, `info <object>`, `flush`),
      #   allowing content and metadata requests to be interleaved in a single process
      #
      # All three modes accept a format string instead of `true` to customise the
      # per-object output line (e.g. `batch: "%(objectname) %(objecttype) %(objectsize)"`)
      #
      # When `batch_all_objects: true` is given instead of object names, git enumerates
      # the entire object database itself and stdin is not read (incompatible with
      # `batch_command:`).
      #
      # Missing objects never cause a non-zero exit — they are reported inline.
      #
      # For single-object queries, use {CatFile::Raw}.
      # For filter-processed content, use {CatFile::Filtered}.
      #
      # @see Git::Commands::CatFile
      #
      # @see https://git-scm.com/docs/git-cat-file git-cat-file documentation
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-cat-file/2.53.0
      #
      # @api private
      #
      class Batch < Base
        arguments do
          literal 'cat-file'

          # Full content mode: header + raw bytes + newline separator per object;
          # accepts a format string to customise the per-object output header
          # (e.g. `"%(objectname) %(objecttype) %(objectsize)"`)
          # @see https://git-scm.com/docs/git-cat-file#Documentation/git-cat-file.txt---batch
          flag_or_value_option :batch, inline: true

          # Metadata-only mode: one `<sha> <type> <size>` line per object;
          # accepts a format string to customise the per-object output line
          # @see https://git-scm.com/docs/git-cat-file#Documentation/git-cat-file.txt---batch-check
          flag_or_value_option :batch_check, inline: true

          # Command-dispatch mode: stdin carries `contents`/`info`/`flush` verbs;
          # accepts a format string to customise the output of `info` and `contents` commands
          # @see https://git-scm.com/docs/git-cat-file#Documentation/git-cat-file.txt---batch-command
          flag_or_value_option :batch_command, inline: true

          # Enumerate all objects in the repository without reading stdin.
          # Incompatible with `batch_command:`.
          # @see https://git-scm.com/docs/git-cat-file#Documentation/git-cat-file.txt---batch-all-objects
          flag_option :batch_all_objects

          # Use normal stdio buffering; enables explicit `flush` semantics when used
          # with `batch_command:` and improves throughput with `batch_check:`
          # @see https://git-scm.com/docs/git-cat-file#Documentation/git-cat-file.txt---buffer
          flag_option :buffer

          # Follow symlinks inside the repository when traversing tree objects
          # @see https://git-scm.com/docs/git-cat-file#Documentation/git-cat-file.txt---follow-symlinks
          flag_option :follow_symlinks

          # Allow `--batch-all-objects` to output objects in an arbitrary, potentially
          # faster order
          # @see https://git-scm.com/docs/git-cat-file#Documentation/git-cat-file.txt---unordered
          flag_option :unordered

          # Apply textconv filters to blob content (combine with `batch_command:`)
          # @see https://git-scm.com/docs/git-cat-file#Documentation/git-cat-file.txt---textconv
          flag_option :textconv

          # Apply the full working-tree filter pipeline (combine with `batch_command:`)
          # @see https://git-scm.com/docs/git-cat-file#Documentation/git-cat-file.txt---filters
          flag_option :filters

          # Map committer/author identities through mailmap for all batch modes
          # @see https://git-scm.com/docs/git-cat-file#Documentation/git-cat-file.txt---use-mailmap
          flag_option :use_mailmap, negatable: true

          # Omit objects matching the filter spec from the output (batched modes only)
          # @see https://git-scm.com/docs/git-cat-file#Documentation/git-cat-file.txt---filterltfilter-specgt
          value_option :filter, inline: true

          # Use NUL-delimited input/output instead of newline-delimited
          # @see https://git-scm.com/docs/git-cat-file#Documentation/git-cat-file.txt--Z
          flag_option :Z

          # Stream stdout to this IO object instead of buffering in memory.
          # When provided, {#call} dispatches to the streaming execution path.
          execution_option :out

          # Object names (or batch-command lines) are written to stdin, not argv.
          # Using skip_cli: true because these values are fed via stdin — git never
          # sees them as CLI arguments so Ruby must enforce the cross-argument
          # constraints below.
          operand :object, repeatable: true, skip_cli: true

          conflicts :object, :batch_all_objects
          requires_one_of :object, :batch_all_objects
        end

        # Execute `git cat-file` in batch stdin-streaming mode.
        #
        # Exactly one of `batch:`, `batch_check:`, or `batch_command:` must be selected.
        # Pass `batch_all_objects: true` instead of object names to enumerate the entire
        # object database without reading stdin.
        #
        # @overload call(*objects, batch: true, **options)
        #   Stream one or more named objects; return header + content per object
        #
        #   @param objects [Array<String>] object names written to stdin
        #
        #   @param batch [Boolean, String] enable `--batch` mode; pass a format string
        #     to customise the per-object output header
        #     (e.g. `"%(objectname) %(objecttype) %(objectsize)"`)
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :buffer (false) Use normal stdio buffering for better throughput
        #
        #   @option options [Boolean] :follow_symlinks (false) Follow symlinks in trees
        #
        #   @option options [Boolean] :unordered (false) Output in arbitrary order
        #
        #   @option options [Boolean] :textconv (false) Apply textconv filters
        #
        #   @option options [Boolean] :filters (false) Apply full working-tree filters
        #
        #   @option options [Boolean] :use_mailmap (false) Remap identities via mailmap
        #
        #     Pass `true` for `--use-mailmap`, `false` for `--no-use-mailmap`.
        #
        #   @option options [String] :filter (nil) Omit objects matching the given filter spec
        #
        #   @option options [Boolean] :Z (false) Use NUL-delimited I/O
        #
        #   @option options [#write, nil] :out (nil) Stream stdout to this IO object
        #     instead of buffering in memory; when given, `result.stdout` will be `''`
        #
        #   @return [Git::CommandLineResult] the result of calling `git cat-file`
        #
        #     Stdout contains the batch output stream (or `''` when `out:` is given)
        #
        #   @raise [ArgumentError] if unsupported options are provided
        #
        #   @raise [Git::FailedError] if git exits non-zero (catastrophic failure only;
        #     missing objects are reported inline)
        #
        # @overload call(*objects, batch_check: true, **options)
        #   Stream one or more named objects; return one metadata line per object
        #
        #   @param objects [Array<String>] object names written to stdin
        #
        #   @param batch_check [Boolean, String] enable `--batch-check` mode; pass a
        #     format string to customise the per-object output line
        #     (e.g. `"%(objectname) %(objecttype) %(objectsize)"`)
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :buffer (false) Use normal stdio buffering for better
        #     throughput when processing large numbers of objects
        #
        #   @option options [Boolean] :follow_symlinks (false) Follow symlinks in trees
        #
        #   @option options [Boolean] :unordered (false) Output in arbitrary order
        #
        #   @option options [Boolean] :textconv (false) Apply textconv filters
        #
        #   @option options [Boolean] :filters (false) Apply full working-tree filters
        #
        #   @option options [Boolean] :use_mailmap (false) Remap identities via mailmap
        #
        #     Pass `true` for `--use-mailmap`, `false` for `--no-use-mailmap`.
        #
        #   @option options [String] :filter (nil) Omit objects matching the given filter spec
        #
        #   @option options [Boolean] :Z (false) Use NUL-delimited I/O
        #
        #   @option options [#write, nil] :out (nil) Stream stdout to this IO object
        #     instead of buffering in memory; when given, `result.stdout` will be `''`
        #
        #   @return [Git::CommandLineResult] the result of calling `git cat-file`
        #
        #     Stdout contains one metadata line per object (or `''` when `out:` is given)
        #
        #   @raise [ArgumentError] if unsupported options are provided
        #
        #   @raise [Git::FailedError] if git exits non-zero (catastrophic failure only;
        #     missing objects are reported inline)
        #
        # @overload call(*objects, batch_command: true, **options)
        #   Dispatch mixed `contents`/`info`/`flush` commands via stdin
        #
        #   Each element of `objects` is written verbatim as a stdin line — the caller
        #   is responsible for prefixing lines with the appropriate verb
        #   (`contents <object>`, `info <object>`, or `flush`).
        #
        #   @param objects [Array<String>] pre-formatted command lines to write to stdin
        #
        #   @param batch_command [Boolean, String] enable `--batch-command` mode; pass
        #     a format string to customise the output of `info` and `contents` commands
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :buffer (false) Use normal stdio buffering for better throughput
        #
        #   @option options [Boolean] :textconv (false) Apply textconv filters
        #
        #   @option options [Boolean] :filters (false) Apply full working-tree filters
        #
        #   @option options [Boolean] :use_mailmap (false) Remap identities via mailmap
        #
        #     Pass `true` for `--use-mailmap`, `false` for `--no-use-mailmap`.
        #
        #   @option options [String] :filter (nil) Omit objects matching the given filter spec
        #
        #   @option options [Boolean] :Z (false) Use NUL-delimited I/O
        #
        #   @option options [#write, nil] :out (nil) Stream stdout to this IO object
        #     instead of buffering in memory; when given, `result.stdout` will be `''`
        #
        #   @return [Git::CommandLineResult] the result of calling `git cat-file`
        #
        #     Stdout contains the interleaved command output (or `''` when `out:` is given)
        #
        #   @raise [ArgumentError] if unsupported options are provided
        #
        #   @raise [Git::FailedError] if git exits non-zero
        #
        # @overload call(batch_all_objects: true, batch: true, **options)
        #   Enumerate all objects in the repository with full content
        #
        #   @param batch_all_objects [Boolean] enumerate all objects; stdin is not read
        #
        #   @param batch [Boolean, String] enable `--batch` mode; pass a format string
        #     to customise the per-object output header
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :buffer (false) Use normal stdio buffering for better throughput
        #
        #   @option options [Boolean] :unordered (false) Output in arbitrary order
        #
        #   @option options [Boolean] :use_mailmap (false) Remap identities via mailmap for
        #     commit and tag objects
        #
        #     Pass `true` for `--use-mailmap`, `false` for `--no-use-mailmap`.
        #
        #   @option options [String] :filter (nil) Omit objects matching the given filter spec
        #
        #   @option options [Boolean] :Z (false) Use NUL-delimited I/O
        #
        #   @option options [#write, nil] :out (nil) Stream stdout to this IO object
        #     instead of buffering in memory; when given, `result.stdout` will be `''`
        #
        #   @return [Git::CommandLineResult] the result of calling `git cat-file`
        #
        #     Stdout contains the full batch output (or `''` when `out:` is given)
        #
        #   @raise [ArgumentError] if unsupported options are provided
        #
        #   @raise [Git::FailedError] if git exits non-zero
        #
        # @overload call(batch_all_objects: true, batch_check: true, **options)
        #   Enumerate all objects in the repository with metadata only
        #
        #   @param batch_all_objects [Boolean] enumerate all objects; stdin is not read
        #
        #   @param batch_check [Boolean, String] enable `--batch-check` mode; pass a
        #     format string to customise the per-object output line
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :buffer (false) Use normal stdio buffering for better
        #     throughput when processing large numbers of objects
        #
        #   @option options [Boolean] :unordered (false) Output in arbitrary order
        #
        #   @option options [Boolean] :use_mailmap (false) Remap identities via mailmap for
        #     commit and tag objects
        #
        #     Pass `true` for `--use-mailmap`, `false` for `--no-use-mailmap`.
        #
        #   @option options [String] :filter (nil) Omit objects matching the given filter spec
        #
        #   @option options [Boolean] :Z (false) Use NUL-delimited I/O
        #
        #   @option options [#write, nil] :out (nil) Stream stdout to this IO object
        #     instead of buffering in memory; when given, `result.stdout` will be `''`
        #
        #   @return [Git::CommandLineResult] the result of calling `git cat-file`
        #
        #     Stdout contains one metadata line per object (or `''` when `out:` is given)
        #
        #   @raise [ArgumentError] if unsupported options are provided
        #
        #   @raise [Git::FailedError] if git exits non-zero
        def call(*objects, **)
          bound = args_definition.bind(*objects, **)
          # `-Z` puts git into NUL I/O mode: input objects must be NUL-terminated.
          # Without `-Z`, the standard newline delimiter is used.
          delimiter = bound.Z? ? "\0" : "\n"
          stdin = Array(bound.object).map { |o| "#{o}#{delimiter}" }.join
          with_stdin(stdin) { |reader| run_batch(bound, reader) }
        end

        private

        # Run the bound command with stdin connected to the reader end of the pipe
        #
        # @param bound [Git::Commands::Arguments::Bound] bound argument list
        #
        # @param reader [IO] read end of the stdin pipe
        #
        # @return [Git::CommandLineResult]
        #
        def run_batch(bound, reader)
          result = if bound.execution_options.key?(:out)
                     run_batch_streaming(bound, reader)
                   else
                     run_batch_capturing(bound, reader)
                   end
          validate_exit_status!(result)
          result
        end

        def run_batch_streaming(bound, reader)
          @execution_context.command_streaming(
            *bound,
            in: reader,
            **bound.execution_options,
            raise_on_failure: false
          )
        end

        def run_batch_capturing(bound, reader)
          @execution_context.command_capturing(
            *bound,
            in: reader,
            **bound.execution_options,
            normalize: false,
            chomp: false,
            raise_on_failure: false
          )
        end
      end
    end
  end
end
