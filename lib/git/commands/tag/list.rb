# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Tag
      # Implements the `git tag --list` command
      #
      # This command lists existing tags with optional filtering and sorting.
      #
      # @example Basic tag listing
      #   list = Git::Commands::Tag::List.new(execution_context)
      #   tags = list.call
      #
      # @example List tags matching a pattern
      #   list = Git::Commands::Tag::List.new(execution_context)
      #   tags = list.call('v1.*')
      #
      # @example List tags containing a commit
      #   list = Git::Commands::Tag::List.new(execution_context)
      #   tags = list.call(contains: 'abc123')
      #
      # @example List tags with multiple patterns
      #   list = Git::Commands::Tag::List.new(execution_context)
      #   tags = list.call('v1.*', 'v2.*', sort: 'version:refname')
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-tag/2.53.0
      #
      # @see Git::Commands::Tag
      #
      # @see https://git-scm.com/docs/git-tag git-tag
      #
      # @api private
      #
      class List < Git::Commands::Base
        arguments do
          literal 'tag'
          literal '--list'

          # Annotation display
          flag_or_value_option :n, inline: true

          # Output ordering and presentation
          value_option :sort, inline: true, repeatable: true
          flag_or_value_option :color, inline: true
          flag_option %i[ignore_case i]
          flag_option :omit_empty
          flag_or_value_option :column, negatable: true, inline: true

          # Filtering
          flag_or_value_option :contains
          flag_or_value_option :no_contains
          flag_or_value_option :merged
          flag_or_value_option :no_merged
          flag_or_value_option :points_at

          # Output format
          value_option :format, inline: true

          end_of_options
          operand :pattern, repeatable: true
        end

        # @!method call(*, **)
        #
        #   Execute the git tag --list command
        #
        #   @overload call(*pattern, **options)
        #
        #     @param pattern [Array<String>] Shell wildcard patterns to filter tags
        #
        #       Multiple patterns can be provided; a tag is shown if it matches any pattern.
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean, Integer] :n (nil) Number of annotation lines to print
        #
        #       Pass `true` to print the first annotation line, or an integer to print that
        #       many lines. If the tag is not annotated, the commit message is displayed instead.
        #
        #     @option options [String, Array<String>] :sort (nil) Sort tags by the specified
        #       key(s)
        #
        #       Prefix `-` to sort in descending order. Common keys: 'refname',
        #       '-refname', 'creatordate', '-creatordate', 'version:refname' (for semantic
        #       version sorting).
        #
        #     @option options [Boolean, String] :color (nil) Colorize output per colors
        #       specified in `--format`
        #
        #       Pass `true` for `--color`, or one of `'always'`, `'never'`, `'auto'`.
        #
        #     @option options [Boolean] :ignore_case (false) Sorting and filtering tags are
        #       case insensitive
        #
        #       Alias: :i
        #
        #     @option options [Boolean] :omit_empty (false) Do not print a newline after
        #       formatted refs where the format expands to the empty string
        #
        #     @option options [Boolean, String] :column (false) Display tag listing in columns
        #
        #       Pass `true` for `--column` or a comma-separated options string
        #       (see `column.tag` configuration for syntax) for `--column=<options>`.
        #
        #     @option options [Boolean] :no_column (false) disable column output (`--no-column`)
        #
        #     @option options [Boolean, String] :contains (nil) List only tags that contain the
        #       specified commit
        #
        #       Pass `true` to use HEAD, or a commit reference string.
        #
        #     @option options [Boolean, String] :no_contains (nil) List only tags that don't contain
        #       the specified commit
        #
        #       Pass `true` to use HEAD, or a commit reference string.
        #
        #     @option options [Boolean, String] :merged (nil) List only tags whose commits are
        #       reachable from the specified commit
        #
        #       Pass `true` to use HEAD, or a commit reference string.
        #
        #     @option options [Boolean, String] :no_merged (nil) List only tags whose commits are
        #       not reachable from the specified commit
        #
        #       Pass `true` to use HEAD, or a commit reference string.
        #
        #     @option options [Boolean, String] :points_at (nil) List only tags that point at the
        #       specified object
        #
        #       Pass `true` to use HEAD, or an object reference string.
        #
        #     @option options [String] :format (nil) Output format string for each tag
        #
        #     @return [Git::CommandLineResult] the result of calling `git tag --list`
        #
        #     @raise [Git::FailedError] if git returns a non-zero exit code
        #
      end
    end
  end
end
