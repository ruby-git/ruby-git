# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git grep` command
    #
    # Searches for a pattern in the contents of tracked files within a repository
    # tree.
    #
    # @see https://git-scm.com/docs/git-grep git-grep
    #
    # @see Git::Commands
    #
    # @api private
    #
    # @example Search for a pattern in HEAD
    #   grep = Git::Commands::Grep.new(execution_context)
    #   result = grep.call('HEAD', pattern: 'search')
    #
    # @example Case-insensitive search
    #   grep = Git::Commands::Grep.new(execution_context)
    #   result = grep.call('HEAD', pattern: 'SEARCH', ignore_case: true)
    #
    # @example Invert match (lines that do NOT match)
    #   grep = Git::Commands::Grep.new(execution_context)
    #   result = grep.call('HEAD', pattern: 'search', invert_match: true)
    #
    # @example Extended regexp
    #   grep = Git::Commands::Grep.new(execution_context)
    #   result = grep.call('HEAD', pattern: 'foo|bar', extended_regexp: true)
    #
    # @example Limit search to specific paths
    #   grep = Git::Commands::Grep.new(execution_context)
    #   result = grep.call('HEAD', pattern: 'search', pathspec: 'lib/**')
    #
    # @example Multiple pathspecs
    #   grep = Git::Commands::Grep.new(execution_context)
    #   result = grep.call('HEAD', pattern: 'search', pathspec: ['lib/**', 'spec/**'])
    #
    # @example Compound boolean expression (raw args passthrough)
    #   grep = Git::Commands::Grep.new(execution_context)
    #   result = grep.call('HEAD', pattern: ['-e', 'foo', '--and', '-e', 'bar'])
    #
    # @example Search across multiple trees
    #   grep = Git::Commands::Grep.new(execution_context)
    #   result = grep.call('main', 'feature', pattern: 'search')
    #
    class Grep < Git::Commands::Base
      arguments do
        literal 'grep'
        literal '--no-color'

        # Encoding and binary handling
        flag_option %i[text a]
        flag_option :I
        flag_option :textconv, negatable: true

        # Pattern matching behaviour
        flag_option %i[ignore_case i]
        flag_option %i[word_regexp w]
        flag_option %i[invert_match v]
        flag_option :full_name

        # Regexp flavour
        flag_option %i[extended_regexp E]
        flag_option %i[basic_regexp G]
        flag_option %i[perl_regexp P]
        flag_option %i[fixed_strings F]

        # Output format
        flag_option %i[line_number n]
        flag_option :H
        flag_option :h
        flag_option :column
        flag_option :break
        flag_option :heading
        flag_option %i[files_with_matches name_only l]
        flag_option %i[files_without_match L]
        flag_option %i[only_matching o]
        flag_option %i[count c]
        flag_option :all_match
        flag_option %i[quiet q]

        # Depth and recursion
        value_option :max_depth
        flag_option %i[recursive r], negatable: true

        # Display
        flag_option %i[show_function p]

        # Context lines
        value_option %i[after_context A], inline: true
        value_option %i[before_context B], inline: true
        value_option %i[context C], inline: true
        flag_option %i[function_context W]

        # Limits and performance
        value_option %i[max_count m]
        value_option :threads

        # Source selection
        flag_option :recurse_submodules
        flag_option :exclude_standard, negatable: true
        flag_option :cached
        flag_option :untracked
        flag_option :no_index

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

        operand :tree, repeatable: true
        value_option :pathspec, as_operand: true, separator: '--', repeatable: true
      end

      # `git grep` exits with 1 when no lines are selected — not an error
      allow_exit_status 0..1

      # @!method call(*, **)
      #
      #   Execute the `git grep` command.
      #
      #   @overload call(*tree, **options)
      #
      #     @param tree [String] one or more tree-ish references to search
      #       (e.g. commit SHAs, tags, or branch names); when omitted, git
      #       searches the working tree
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :text (nil) Process binary files as if they
      #       were text
      #
      #       Alias: :a
      #
      #     @option options [Boolean] :I (nil) Do not match the pattern in binary
      #       files
      #
      #     @option options [Boolean] :textconv (nil) Honor textconv filter settings
      #
      #       Pass +false+ to emit +--no-textconv+.
      #
      #     @option options [Boolean] :ignore_case (nil) Ignore case
      #       distinctions in both the pattern and the file contents
      #
      #       Alias: :i
      #
      #     @option options [Boolean] :word_regexp (nil) Match the pattern only at
      #       word boundary
      #
      #       Alias: :w
      #
      #     @option options [Boolean] :invert_match (nil) Select non-matching
      #       lines
      #
      #       Alias: :v
      #
      #     @option options [Boolean] :full_name (nil) Output paths relative to the
      #       project top directory rather than the current directory
      #
      #     @option options [Boolean] :extended_regexp (nil) Use POSIX extended
      #       regular expressions for the pattern
      #
      #       Alias: :E
      #
      #     @option options [Boolean] :basic_regexp (nil) Use POSIX basic regular
      #       expressions for the pattern (the default regexp flavour)
      #
      #       Alias: :G
      #
      #     @option options [Boolean] :perl_regexp (nil) Use Perl-compatible regular
      #       expressions for the pattern
      #
      #       Alias: :P
      #
      #     @option options [Boolean] :fixed_strings (nil) Treat the pattern as a
      #       fixed string rather than a regular expression
      #
      #       Alias: :F
      #
      #     @option options [Boolean] :line_number (nil) Prefix each matching line
      #       with its line number within the file
      #
      #       Alias: :n
      #
      #     @option options [Boolean] :H (nil) Print the filename for each match
      #
      #     @option options [Boolean] :h (nil) Suppress the filename prefix for each
      #       match
      #
      #     @option options [Boolean] :column (nil) Prefix the 1-indexed byte-offset
      #       of the first match from the start of the matching line
      #
      #     @option options [Boolean] :break (nil) Print an empty line between matches
      #       from different files
      #
      #     @option options [Boolean] :heading (nil) Show the filename above the
      #       matches in that file instead of at the start of each shown line
      #
      #     @option options [Boolean] :files_with_matches (nil) Show only the names
      #       of files that contain matches, not the matching lines
      #
      #       Aliases: :name_only, :l
      #
      #     @option options [Boolean] :files_without_match (nil) Show only the names
      #       of files that do not contain matches
      #
      #       Alias: :L
      #
      #     @option options [Boolean] :only_matching (nil) Print only the matched
      #       (non-empty) parts of a matching line, each on a separate output line
      #
      #       Alias: :o
      #
      #     @option options [Boolean] :count (nil) Show the number of matching lines
      #       per file instead of the matching lines themselves
      #
      #       Alias: :c
      #
      #     @option options [Boolean] :all_match (nil) When using multiple +--or+
      #       patterns, limit matches to files that have lines matching all of them
      #
      #     @option options [Boolean] :quiet (nil) Do not output matching lines;
      #       exit 0 when there is a match and non-zero when there is not
      #
      #       Alias: :q
      #
      #     @option options [Integer] :max_depth (nil) Descend at most the given
      #       number of directory levels for each pathspec argument
      #
      #     @option options [Boolean] :recursive (nil) Recurse into subdirectories
      #       (same as +--max-depth=-1+; this is the default)
      #
      #       Pass +false+ to emit +--no-recursive+ (+--max-depth=0+).
      #
      #       Alias: :r
      #
      #     @option options [Boolean] :show_function (nil) Show the nearest function
      #       name preceding each match
      #
      #       Alias: :p
      #
      #     @option options [Integer] :after_context (nil) Show the given number of
      #       trailing lines after each match
      #
      #       Alias: :A
      #
      #     @option options [Integer] :before_context (nil) Show the given number of
      #       leading lines before each match
      #
      #       Alias: :B
      #
      #     @option options [Integer] :context (nil) Show the given number of leading
      #       and trailing lines around each match
      #
      #       Alias: :C
      #
      #     @option options [Boolean] :function_context (nil) Show the surrounding
      #       text from the previous function name up to the next, effectively
      #       showing the whole function in which the match was found
      #
      #       Alias: :W
      #
      #     @option options [Integer] :max_count (nil) Limit the number of matches
      #       per file
      #
      #       Alias: :m
      #
      #     @option options [Integer] :threads (nil) Number of grep worker threads
      #       to use
      #
      #     @option options [Boolean] :recurse_submodules (nil) Recursively search
      #       in each active, checked-out submodule
      #
      #     @option options [Boolean] :exclude_standard (nil) Honor the +.gitignore+
      #       mechanism when searching untracked files
      #
      #       Pass +false+ to emit +--no-exclude-standard+ and also search ignored
      #       files. Only useful with +:untracked+ or +:no_index+.
      #
      #     @option options [Boolean] :cached (nil) Search blobs registered in the
      #       index instead of tracked files in the working tree
      #
      #     @option options [Boolean] :untracked (nil) Search untracked files in
      #       addition to tracked files in the working tree
      #
      #     @option options [Boolean] :no_index (nil) Search files in the current
      #       directory without regard to whether it is managed by Git
      #
      #     @option options [String, Array<String>] :f (nil) Read patterns from a
      #       file, one per line; may be passed as an Array to supply multiple
      #       pattern files
      #
      #     @option options [String, Array<String>] :pattern The search pattern
      #       (required; must not be nil)
      #
      #       Pass a String for a simple pattern (emitted as `-e <pattern>`).
      #       Pass an Array of raw CLI arguments for compound boolean
      #       expressions (e.g. `['-e', 'foo', '--and', '-e', 'bar']`).
      #
      #     @option options [String, Array<String>] :pathspec (nil) Limit the
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
      #     @raise [ArgumentError] if +:pattern+ is missing or nil
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if the command returns exit status greater
      #       than 1
    end
  end
end
