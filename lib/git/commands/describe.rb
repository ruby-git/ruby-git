# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git describe` command
    #
    # Gives a human-readable name to a commit based on the most recent
    # reachable tag. When the tag points directly at the commit, only the
    # tag name is shown. Otherwise, the tag name is suffixed with the number
    # of additional commits and the abbreviated commit SHA.
    #
    # @example Typical usage
    #   describe = Git::Commands::Describe.new(execution_context)
    #   describe.call
    #   describe.call('abc123')
    #   describe.call(tags: true)
    #   describe.call(dirty: true)
    #   describe.call(dirty: '-dirty')
    #
    # @note `arguments` block audited against
    #   https://git-scm.com/docs/git-describe/2.53.0
    #
    # @see https://git-scm.com/docs/git-describe git-describe
    #
    # @see Git::Commands
    #
    # @api private
    #
    class Describe < Git::Commands::Base
      arguments do
        literal 'describe'

        # Ref selection
        flag_option :all
        flag_option :tags
        flag_option :contains

        # Abbreviation
        flag_or_value_option :abbrev, inline: true

        # Working tree state
        flag_or_value_option :dirty, inline: true
        flag_or_value_option :broken, inline: true

        # Match candidates
        value_option :candidates, inline: true
        flag_option :exact_match

        # Output control
        flag_option :debug
        flag_option :long

        # Pattern filtering
        value_option :match, repeatable: true
        value_option :exclude, repeatable: true

        # Fallback and history
        flag_option :always
        flag_option :first_parent

        end_of_options
        operand :commit_ish, repeatable: true
      end

      # @!method call(*, **)
      #
      #   @overload call(*commit_ish, **options)
      #
      #     Execute the `git describe` command
      #
      #     @param commit_ish [Array<String>] zero or more commit-ish objects
      #       to describe
      #
      #       When none are given, describes HEAD.
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :all (false) use any ref found in the
      #       `refs/` namespace, not just tags
      #
      #     @option options [Boolean] :tags (false) use any tag found in the
      #       `refs/tags` namespace, instead of only annotated tags
      #
      #     @option options [Boolean] :contains (false) find the tag that
      #       comes after the commit and thus contains it, rather than the
      #       most recent tag reachable from it
      #
      #     @option options [Boolean, String] :abbrev (nil) use this many
      #       digits for the abbreviated commit object name
      #
      #       When `true`, emits bare `--abbrev` (which uses git's default
      #       length). Pass a string to emit `--abbrev=<n>`.
      #
      #     @option options [Boolean, String] :dirty (nil) describe the
      #       working tree
      #
      #       When `true`, appends `-dirty`; when a String, appends that
      #       string as the dirty mark. Maps to `--dirty[=<mark>]`.
      #
      #     @option options [Boolean, String] :broken (nil) describe the
      #       working tree, treating broken links as dirty
      #
      #       When `true`, appends `-broken`; when a String, appends that
      #       string as the broken mark. Maps to `--broken[=<mark>]`.
      #
      #     @option options [Integer, String] :candidates (nil) consider up
      #       to this many candidates
      #
      #       Increasing above the default of 10 will take a slightly
      #       longer time but may produce a more accurate result. Maps to
      #       `--candidates=<n>`.
      #
      #     @option options [Boolean] :exact_match (false) only output exact
      #       matches (a tag directly references the supplied commit object)
      #
      #     @option options [Boolean] :debug (false) verbosely display
      #       information about the searching strategy being employed
      #
      #     @option options [Boolean] :long (false) always output the long
      #       format (the tag, the number of commits, and the abbreviated
      #       object name) even when it matches a tag exactly
      #
      #     @option options [String, Array<String>] :match (nil) only
      #       consider tags matching the given `glob(7)` pattern
      #
      #       Pass an array to match against multiple patterns. Maps to
      #       `--match <pattern>`.
      #
      #     @option options [String, Array<String>] :exclude (nil) do not
      #       consider tags matching the given `glob(7)` pattern
      #
      #       Pass an array to exclude multiple patterns. Maps to
      #       `--exclude <pattern>`.
      #
      #     @option options [Boolean] :always (false) show uniquely
      #       abbreviated commit object as fallback when the commit cannot
      #       be described
      #
      #     @option options [Boolean] :first_parent (false) follow only the
      #       first parent of a merge commit
      #
      #     @return [Git::CommandLineResult] the result of calling
      #       `git describe`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if git exits with a non-zero exit
      #       status
      #
      #     @api public
    end
  end
end
