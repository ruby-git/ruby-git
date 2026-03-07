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
    # @see https://git-scm.com/docs/git-describe git-describe
    # @see Git::Commands
    #
    # @api private
    #
    # @example Describe the current HEAD
    #   describe = Git::Commands::Describe.new(execution_context)
    #   result = describe.call
    #
    # @example Describe a specific commit
    #   describe = Git::Commands::Describe.new(execution_context)
    #   result = describe.call('abc123')
    #
    # @example Describe using any tag (not just annotated)
    #   describe = Git::Commands::Describe.new(execution_context)
    #   result = describe.call(tags: true)
    #
    # @example Describe with dirty-tree marker
    #   describe = Git::Commands::Describe.new(execution_context)
    #   result = describe.call(dirty: true)
    #   result = describe.call(dirty: '-dirty')
    #
    class Describe < Git::Commands::Base
      arguments do
        literal 'describe'
        flag_option :all
        flag_option :tags
        flag_option :contains
        flag_option :debug
        flag_option :long
        flag_option :always
        flag_option :exact_match
        flag_option :first_parent
        flag_or_value_option :dirty, inline: true
        flag_or_value_option :broken, inline: true
        flag_or_value_option :abbrev, inline: true
        value_option :candidates, inline: true
        value_option :match, repeatable: true
        value_option :exclude, repeatable: true
        operand :commit_ish, repeatable: true
        conflicts :exact_match, :candidates
        conflicts :dirty, :commit_ish
        conflicts :broken, :commit_ish
      end

      # @!method call(*, **)
      #
      #   Execute the git describe command
      #
      #   @overload call(*commit_ish, **options)
      #
      #     @param commit_ish [Array<String>] zero or more commit-ish objects to describe.
      #       When none are given, describes HEAD.
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :all (nil) Use any ref found in the `refs/`
      #       namespace, not just tags.
      #
      #     @option options [Boolean] :tags (nil) Use any tag found in the `refs/tags`
      #       namespace, instead of only annotated tags.
      #
      #     @option options [Boolean] :contains (nil) Find the tag that comes after
      #       the commit and thus contains it, rather than the most recent tag
      #       reachable from it.
      #
      #     @option options [Boolean] :debug (nil) Verbosely display information
      #       about the searching strategy being employed.
      #
      #     @option options [Boolean] :long (nil) Always output the long format
      #       (the tag, the number of commits, and the abbreviated object name)
      #       even when it matches a tag exactly.
      #
      #     @option options [Boolean] :always (nil) Show uniquely abbreviated
      #       commit object as fallback when the commit cannot be described.
      #
      #     @option options [Boolean] :exact_match (nil) Only output exact matches
      #       (a tag directly references the supplied commit object). Maps to
      #       `--exact-match`.
      #
      #     @option options [Boolean] :first_parent (nil) Follow only the first
      #       parent of a merge commit. Maps to `--first-parent`.
      #
      #     @option options [Boolean, String] :abbrev (nil) Use this many digits (or
      #       as many as needed to form a unique object name) for the abbreviated
      #       commit object name. When `true`, emits bare `--abbrev` (which uses
      #       git's default length). Maps to `--abbrev[=<n>]`.
      #
      #     @option options [String] :candidates (nil) Consider up to this many
      #       candidates. Increasing above the default of 10 will take a slightly
      #       longer time but may produce a more accurate result. Maps to
      #       `--candidates=<n>`.
      #
      #     @option options [String, Array<String>] :match (nil) Only consider tags
      #       matching the given `glob(7)` pattern. Pass an array to match against
      #       multiple patterns. Maps to `--match <pattern>`.
      #
      #     @option options [String, Array<String>] :exclude (nil) Do not consider
      #       tags matching the given `glob(7)` pattern. Pass an array to exclude
      #       multiple patterns. Maps to `--exclude <pattern>`.
      #
      #     @option options [Boolean, String] :dirty (nil) Describe the working
      #       tree. When `true`, appends `-dirty`; when a String, appends that
      #       string as the dirty mark. Maps to `--dirty[=<mark>]`.
      #
      #     @option options [Boolean, String] :broken (nil) Describe the working
      #       tree, treating broken links as dirty. When `true`, appends `-broken`;
      #       when a String, appends that string as the broken mark. Maps to
      #       `--broken[=<mark>]`.
      #
      #     @return [Git::CommandLineResult] the result of calling `git describe`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if the command returns a non-zero exit status
    end
  end
end
