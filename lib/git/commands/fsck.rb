# frozen_string_literal: true

require 'git/commands/arguments'
require 'git/parsers/fsck'

module Git
  module Commands
    # Implements the `git fsck` command
    #
    # This command verifies the connectivity and validity of objects in the database.
    # It checks the integrity of the repository, reporting any dangling, missing, or
    # unreachable objects.
    #
    # @api private
    #
    # @example Basic usage
    #   fsck = Git::Commands::Fsck.new(execution_context)
    #   result = fsck.call
    #   puts "Found #{result.count} issues" if result.any_issues?
    #
    # @example With specific objects
    #   fsck = Git::Commands::Fsck.new(execution_context)
    #   result = fsck.call('abc1234', 'def5678')
    #
    # @example With options
    #   fsck = Git::Commands::Fsck.new(execution_context)
    #   result = fsck.call(unreachable: true, strict: true)
    #
    class Fsck
      # Arguments DSL for building command-line arguments
      ARGS = Arguments.define do
        literal 'fsck'
        literal '--no-progress'
        flag_option :unreachable
        flag_option :strict
        flag_option :connectivity_only
        flag_option :root
        flag_option :tags
        flag_option :cache
        flag_option :no_reflogs
        flag_option :lost_found
        flag_option :dangling, negatable: true
        flag_option :full, negatable: true
        flag_option :name_objects, negatable: true
        flag_option :references, negatable: true
        operand :objects, repeatable: true
      end.freeze

      # Initialize the Fsck command
      #
      # @param execution_context [Git::ExecutionContext, Git::Lib] the context for executing git commands
      #
      def initialize(execution_context)
        @execution_context = execution_context
      end

      # Execute the git fsck command
      #
      # @overload call(*objects, **options)
      #
      #   @param objects [Array<String>] optional object identifiers to check
      #
      #   @param options [Hash] command options
      #
      #   @option options [Boolean] :unreachable Print out objects that exist but aren't
      #     reachable from any of the reference nodes
      #
      #   @option options [Boolean] :strict Enable more strict checking
      #
      #   @option options [Boolean] :connectivity_only Check only the connectivity
      #
      #   @option options [Boolean] :root Report root nodes
      #
      #   @option options [Boolean] :tags Report tags
      #
      #   @option options [Boolean] :cache Consider any object recorded in the index also as a head node
      #
      #   @option options [Boolean] :no_reflogs Don't check reflogs
      #
      #   @option options [Boolean] :lost_found Write dangling objects into .git/lost-found
      #
      #   @option options [Boolean] :dangling Print out dangling objects (default true, set false to disable)
      #
      #   @option options [Boolean] :full Check all objects, not just reachable ones (default false, set true to enable)
      #
      #   @option options [Boolean] :name_objects Show name of each object from refs (default false, set true to enable)
      #
      #   @option options [Boolean] :references Check reference objects (default true, set false to disable)
      #
      # @return [Git::FsckResult] the structured result containing categorized objects
      #
      def call(*, **)
        args = ARGS.bind(*, **)
        result = @execution_context.command(*args, raise_on_failure: false)

        # fsck returns non-zero exit status when issues are found:
        # 1 = errors found, 2 = missing objects, 4 = warnings
        # These are bit flags that can be combined (0-7 are valid)
        raise Git::FailedError, result if result.status.exitstatus > 7

        Git::Parsers::Fsck.parse(result.stdout)
      end
    end
  end
end
