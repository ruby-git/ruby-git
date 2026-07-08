# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git name-rev` command
    #
    # Finds symbolic names suitable for human digestion for revisions given
    # in any format parsable by `git rev-parse`.
    #
    # @example Find the symbolic name for a commit
    #   name_rev = Git::Commands::NameRev.new(execution_context)
    #   result = name_rev.call('abc123')
    #
    # @example Use only tags for naming
    #   name_rev = Git::Commands::NameRev.new(execution_context)
    #   result = name_rev.call('abc123', tags: true)
    #
    # @example List all commits reachable from all refs
    #   name_rev = Git::Commands::NameRev.new(execution_context)
    #   result = name_rev.call(all: true)
    #
    # @example Filter refs by pattern
    #   name_rev = Git::Commands::NameRev.new(execution_context)
    #   result = name_rev.call('abc123', refs: ['heads/*', 'tags/*'])
    #
    # @note `arguments` block audited against https://git-scm.com/docs/git-name-rev/2.53.0
    #
    # @see https://git-scm.com/docs/git-name-rev git-name-rev
    #
    # @api private
    #
    class NameRev < Git::Commands::Base
      arguments do
        literal 'name-rev'

        # Ref filtering
        flag_option :tags
        value_option :refs, inline: true, repeatable: true
        flag_option :no_refs
        value_option :exclude, inline: true, repeatable: true
        flag_option :no_exclude

        # Output control
        flag_option :all
        flag_option :annotate_stdin
        flag_option :name_only
        flag_option :no_undefined
        flag_option :always

        end_of_options

        operand :commit_ish, repeatable: true
      end

      # @!method call(*, **options)
      #
      #   @param options [Hash] command options
      #
      #   @option options [Boolean, nil] :tags (nil) command option key; see overload docs
      #     for the full option list
      #
      #   @overload call(*commit_ish, **options)
      #
      #     Execute the `git name-rev` command
      #
      #     @param commit_ish [Array<String>] zero or more commit-ish objects
      #       to find symbolic names for
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean, nil] :tags (nil) use only tags to name
      #       the commits, not branch names
      #
      #     @option options [String, Array<String>] :refs (nil) only use refs
      #       whose names match the given shell pattern
      #
      #       When given multiple times, uses refs whose names match any of the
      #       given shell patterns. Maps to `--refs=<pattern>`.
      #
      #     @option options [Boolean, nil] :no_refs (nil) clear all previously given
      #       `--refs` patterns
      #
      #     @option options [String, Array<String>] :exclude (nil) do not use
      #       any ref whose name matches the given shell pattern
      #
      #       When given multiple times, a ref is excluded when it matches any
      #       of the given patterns. Maps to `--exclude=<pattern>`.
      #
      #     @option options [Boolean, nil] :no_exclude (nil) clear all previously
      #       given `--exclude` patterns
      #
      #     @option options [Boolean, nil] :all (nil) list all commits reachable
      #       from all refs
      #
      #     @option options [Boolean, nil] :annotate_stdin (nil) transform stdin by
      #       substituting all 40-character SHA-1 hexes with their symbolic
      #       names. Maps to `--annotate-stdin`.
      #
      #     @option options [Boolean, nil] :name_only (nil) print only the symbolic
      #       name, not the SHA-1
      #
      #     @option options [Boolean, nil] :no_undefined (nil) die with non-zero
      #       exit code when a reference is undefined, instead of printing
      #       `undefined`
      #
      #     @option options [Boolean, nil] :always (nil) show uniquely abbreviated
      #       commit object as fallback
      #
      #     @return [Git::CommandLineResult] the result of calling
      #       `git name-rev`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if git exits with a non-zero status
    end
  end
end
