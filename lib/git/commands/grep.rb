# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git grep` command
    #
    # Searches for a pattern in the contents of tracked files within a repository
    # tree.
    #
    # @example Typical usage
    #   grep = Git::Commands::Grep.new(execution_context)
    #   grep.call('HEAD', pattern: 'search')
    #   grep.call('HEAD', pattern: 'SEARCH', ignore_case: true)
    #   grep.call('HEAD', pattern: 'search', invert_match: true)
    #   grep.call('HEAD', pattern: 'foo|bar', extended_regexp: true)
    #   grep.call('HEAD', pattern: 'search', pathspec: 'lib/**')
    #
    # @note `arguments` block audited against
    #   https://git-scm.com/docs/git-grep/2.53.0
    #
    # @see https://git-scm.com/docs/git-grep git-grep
    #
    # @see Git::Commands
    #
    # @api private
    #
    class Grep < Git::Commands::Base
      arguments do
        literal 'grep'

        # Encoding and binary handling
        flag_option %i[text a]
        flag_option :I
        flag_option :textconv, negatable: true

        # Pattern matching
        flag_option %i[ignore_case i]
        flag_option %i[word_regexp w]
        flag_option %i[invert_match v]
        flag_option :h
        flag_option :H
        flag_option :full_name

        # Regexp flavour
        flag_option %i[extended_regexp E]
        flag_option %i[basic_regexp G]
        flag_option %i[perl_regexp P]
        flag_option %i[fixed_strings F]

        # Output format
        flag_option %i[line_number n]
        flag_option :column
        flag_option %i[files_with_matches name_only l]
        flag_option %i[files_without_match L]
        flag_option %i[null z]
        flag_option %i[only_matching o]
        flag_option %i[count c]
        flag_option :all_match
        flag_option %i[quiet q]

        # Depth and recursion
        value_option :max_depth
        flag_option %i[recursive r], negatable: true

        # Color
        flag_or_value_option :color, inline: true
        flag_option :no_color

        # Display
        flag_option :break
        flag_option :heading
        flag_option %i[show_function p]

        # Context lines
        value_option %i[after_context A], inline: true
        value_option %i[before_context B], inline: true
        value_option %i[context C], inline: true
        flag_option %i[function_context W]

        # Limits and performance
        value_option %i[max_count m]
        value_option :threads

        # Pattern input
        value_option :f, repeatable: true

        # Accepts a String (simple pattern) or an Array (raw CLI args passthrough
        # for compound boolean expressions like ['-e', 'foo', '--and', '-e', 'bar']).
        custom_option :pattern, required: true, allow_nil: false do |value|
          case value
          when String then ['-e', value]
          when Array then value
          else raise ArgumentError, ":pattern must be a String or Array, got #{value.class}"
          end
        end

        # Source selection
        flag_option :recurse_submodules
        value_option :parent_basename
        flag_option :exclude_standard, negatable: true
        flag_option :cached
        flag_option :untracked
        flag_option :no_index

        operand :tree, repeatable: true
        end_of_options
        value_option :pathspec, as_operand: true, repeatable: true
      end

      # `git grep` exits with 1 when no lines are selected — not an error
      allow_exit_status 0..1

      # @!method call(*, **)
      #
      #   @overload call(*tree, **options)
      #
      #     Execute the `git grep` command
      #
      #     @param tree [Array<String>] zero or more tree-ish references to search
      #       (e.g. commit SHAs, tags, or branch names); when omitted, git
      #       searches the working tree
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :text (false) process binary files as if they
      #       were text
      #
      #       Alias: :a
      #
      #     @option options [Boolean] :I (false) do not match the pattern in binary
      #       files
      #
      #     @option options [Boolean] :textconv (false) honor textconv filter
      #       settings (`--textconv`)
      #
      #     @option options [Boolean] :no_textconv (false) suppress textconv filter
      #       processing (`--no-textconv`)
      #
      #     @option options [Boolean] :ignore_case (false) ignore case distinctions
      #       in both the pattern and the file contents
      #
      #       Alias: :i
      #
      #     @option options [Boolean] :word_regexp (false) match the pattern only at
      #       word boundary
      #
      #       Alias: :w
      #
      #     @option options [Boolean] :invert_match (false) select non-matching lines
      #
      #       Alias: :v
      #
      #     @option options [Boolean] :h (false) suppress the filename prefix for
      #       each match
      #
      #     @option options [Boolean] :H (false) print the filename for each match;
      #       overrides `:h` given earlier
      #
      #     @option options [Boolean] :full_name (false) output paths relative to
      #       the project top directory rather than the current directory
      #
      #     @option options [Boolean] :extended_regexp (false) use POSIX extended
      #       regular expressions for the pattern
      #
      #       Alias: :E
      #
      #     @option options [Boolean] :basic_regexp (false) use POSIX basic regular
      #       expressions for the pattern (the default regexp flavour)
      #
      #       Alias: :G
      #
      #     @option options [Boolean] :perl_regexp (false) use Perl-compatible
      #       regular expressions for the pattern
      #
      #       Alias: :P
      #
      #     @option options [Boolean] :fixed_strings (false) treat the pattern as a
      #       fixed string rather than a regular expression
      #
      #       Alias: :F
      #
      #     @option options [Boolean] :line_number (false) prefix each matching line
      #       with its line number within the file
      #
      #       Alias: :n
      #
      #     @option options [Boolean] :column (false) prefix the 1-indexed
      #       byte-offset of the first match from the start of the matching line
      #
      #     @option options [Boolean] :files_with_matches (false) show only the
      #       names of files that contain matches, not the matching lines
      #
      #       Aliases: :name_only, :l
      #
      #     @option options [Boolean] :files_without_match (false) show only the
      #       names of files that do not contain matches
      #
      #       Alias: :L
      #
      #     @option options [Boolean] :null (false) use NUL as the delimiter for
      #       pathnames in the output, printing them verbatim
      #
      #       Alias: :z
      #
      #     @option options [Boolean] :only_matching (false) print only the matched
      #       (non-empty) parts of a matching line, each on a separate output line
      #
      #       Alias: :o
      #
      #     @option options [Boolean] :count (false) show the number of matching
      #       lines per file instead of the matching lines themselves
      #
      #       Alias: :c
      #
      #     @option options [Boolean] :all_match (false) when using multiple `--or`
      #       patterns, limit matches to files that have lines matching all of them
      #
      #     @option options [Boolean] :quiet (false) do not output matching lines;
      #       exit 0 when there is a match and non-zero when there is not
      #
      #       Alias: :q
      #
      #     @option options [Integer, String] :max_depth (nil) descend at most this
      #       many directory levels for each pathspec argument
      #
      #     @option options [Boolean] :recursive (false) recurse into subdirectories
      #       (same as `--max-depth=-1`; this is the default)
      #
      #       Alias: :r
      #
      #     @option options [Boolean] :no_recursive (false) do not recurse into
      #       subdirectories (`--no-recursive`, equivalent to `--max-depth=0`)
      #
      #     @option options [Boolean, String] :color (nil) show colored matches
      #
      #       When `true`, emits bare `--color`. Pass a string to emit
      #       `--color=<when>` (values: `'always'`, `'never'`, `'auto'`).
      #
      #     @option options [Boolean] :no_color (false) turn off match highlighting,
      #       even when the configuration file gives the default to color output
      #
      #     @option options [Boolean] :break (false) print an empty line between
      #       matches from different files
      #
      #     @option options [Boolean] :heading (false) show the filename above the
      #       matches in that file instead of at the start of each shown line
      #
      #     @option options [Boolean] :show_function (false) show the nearest
      #       function name preceding each match
      #
      #       Alias: :p
      #
      #     @option options [Integer, String] :after_context (nil) show this many
      #       trailing lines after each match
      #
      #       Alias: :A
      #
      #     @option options [Integer, String] :before_context (nil) show this many
      #       leading lines before each match
      #
      #       Alias: :B
      #
      #     @option options [Integer, String] :context (nil) show this many leading
      #       and trailing lines around each match
      #
      #       Alias: :C
      #
      #     @option options [Boolean] :function_context (false) show the surrounding
      #       text from the previous function name up to the next
      #
      #       Alias: :W
      #
      #     @option options [Integer, String] :max_count (nil) limit the number of
      #       matches per file
      #
      #       Alias: :m
      #
      #     @option options [Integer, String] :threads (nil) number of grep worker
      #       threads to use
      #
      #     @option options [String, Array<String>] :f (nil) read patterns from a
      #       file, one per line; may be passed as an Array to supply multiple
      #       pattern files
      #
      #     @option options [String, Array<String>] :pattern (nil) the search
      #       pattern (required; must not be nil)
      #
      #       Pass a String for a simple pattern (emitted as `-e <pattern>`).
      #       Pass an Array of raw CLI arguments for compound boolean
      #       expressions (e.g. `['-e', 'foo', '--and', '-e', 'bar']`).
      #
      #     @option options [Boolean] :recurse_submodules (false) recursively search
      #       in each active, checked-out submodule
      #
      #     @option options [String] :parent_basename (nil) override the name used
      #       as a prefix for submodule output when used with `:recurse_submodules`
      #
      #     @option options [Boolean] :exclude_standard (false) honor the `.gitignore`
      #       mechanism when searching untracked files (`--exclude-standard`)
      #
      #     @option options [Boolean] :no_exclude_standard (false) do not honor the
      #       `.gitignore` mechanism; also search ignored files
      #       (`--no-exclude-standard`); only useful with `:untracked` or `:no_index`
      #
      #     @option options [Boolean] :cached (false) search blobs registered in the
      #       index instead of tracked files in the working tree
      #
      #     @option options [Boolean] :untracked (false) search untracked files in
      #       addition to tracked files in the working tree
      #
      #     @option options [Boolean] :no_index (false) search files in the current
      #       directory without regard to whether it is managed by Git
      #
      #     @option options [String, Array<String>] :pathspec (nil) limit the
      #       search to files matching the given pathspec(s)
      #
      #       Multiple pathspecs may be passed as an Array. Appended to the
      #       command after `--`.
      #
      #     @return [Git::CommandLineResult] the result of calling `git grep`
      #
      #       Exit status 0 means matches were found; exit status 1 means no
      #       lines were selected (not an error).
      #
      #     @raise [ArgumentError] if `:pattern` is missing or nil
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if git exits outside the allowed range
      #       (exit code > 1)
      #
      #   @api public
      #
    end
  end
end
