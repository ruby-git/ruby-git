# frozen_string_literal: true

require 'git/commands/arguments'

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
        static 'fsck'
        static '--no-progress'
        flag :unreachable
        flag :strict
        flag :connectivity_only
        flag :root
        flag :tags
        flag :cache
        flag :no_reflogs
        flag :lost_found
        negatable_flag :dangling
        negatable_flag :full
        negatable_flag :name_objects
        negatable_flag :references
        positional :objects, variadic: true
      end.freeze

      # Pattern matchers for parsing fsck output
      OBJECT_PATTERN = /\A(dangling|missing|unreachable) (\w+) ([0-9a-f]{40})(?: \((.+)\))?\z/
      WARNING_PATTERN = /\Awarning in (\w+) ([0-9a-f]{40}): (.+)\z/
      ROOT_PATTERN = /\Aroot ([0-9a-f]{40})\z/
      TAGGED_PATTERN = /\Atagged (\w+) ([0-9a-f]{40}) \((.+)\) in ([0-9a-f]{40})\z/

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
        args = ARGS.build(*, **)

        # fsck returns non-zero exit status when issues are found:
        # 1 = errors found, 2 = missing objects, 4 = warnings
        # We still want to parse the output in these cases
        output = begin
          @execution_context.command(*args)
        rescue Git::FailedError => e
          raise unless [1, 2, 4].include?(e.result.status.exitstatus)

          e.result.stdout
        end

        parse_output(output)
      end

      private

      # Parse the output from git fsck into a structured result
      #
      # @param output [String] the command output
      # @return [Git::FsckResult] the parsed result
      #
      def parse_output(output)
        result = { dangling: [], missing: [], unreachable: [], warnings: [], root: [], tagged: [] }
        output.each_line { |line| parse_line(line.strip, result) }
        Git::FsckResult.new(**result)
      end

      # Parse a single line of fsck output
      #
      # @param line [String] a line of output
      # @param result [Hash] the result hash to populate
      # @return [Boolean] true if the line was parsed
      #
      def parse_line(line, result)
        parse_object_line(line, result) ||
          parse_warning_line(line, result) ||
          parse_root_line(line, result) ||
          parse_tagged_line(line, result)
      end

      # Parse a dangling/missing/unreachable object line
      #
      # @param line [String] a line of output
      # @param result [Hash] the result hash to populate
      # @return [Boolean] true if the line was parsed
      #
      def parse_object_line(line, result)
        return unless (match = OBJECT_PATTERN.match(line))

        result[match[1].to_sym] << Git::FsckObject.new(type: match[2].to_sym, oid: match[3], name: match[4])
      end

      # Parse a warning line
      #
      # @param line [String] a line of output
      # @param result [Hash] the result hash to populate
      # @return [Boolean] true if the line was parsed
      #
      def parse_warning_line(line, result)
        return unless (match = WARNING_PATTERN.match(line))

        result[:warnings] << Git::FsckObject.new(type: match[1].to_sym, oid: match[2], message: match[3])
      end

      # Parse a root line
      #
      # @param line [String] a line of output
      # @param result [Hash] the result hash to populate
      # @return [Boolean] true if the line was parsed
      #
      def parse_root_line(line, result)
        return unless (match = ROOT_PATTERN.match(line))

        result[:root] << Git::FsckObject.new(type: :commit, oid: match[1])
      end

      # Parse a tagged line
      #
      # @param line [String] a line of output
      # @param result [Hash] the result hash to populate
      # @return [Boolean] true if the line was parsed
      #
      def parse_tagged_line(line, result)
        return unless (match = TAGGED_PATTERN.match(line))

        result[:tagged] << Git::FsckObject.new(type: match[1].to_sym, oid: match[2], name: match[3])
      end
    end
  end
end
