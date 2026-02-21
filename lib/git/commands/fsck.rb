# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git fsck` command
    #
    # This command verifies the connectivity and validity of objects in the database.
    # It checks the integrity of the repository, reporting any dangling, missing, or
    # unreachable objects.
    #
    # @see https://git-scm.com/docs/git-fsck git-fsck
    #
    # @api private
    #
    # @example Basic usage
    #   fsck = Git::Commands::Fsck.new(execution_context)
    #   result = fsck.call
    #   result.stdout # => "dangling blob abc123...\n"
    #
    # @example With specific objects
    #   fsck = Git::Commands::Fsck.new(execution_context)
    #   result = fsck.call('abc1234', 'def5678')
    #
    # @example With options
    #   fsck = Git::Commands::Fsck.new(execution_context)
    #   result = fsck.call(unreachable: true, strict: true)
    #
    class Fsck < Base
      arguments do
        literal 'fsck'
        literal '--no-progress'
        flag_option :tags
        flag_option :root
        flag_option :unreachable
        flag_option :cache
        flag_option :no_reflogs
        flag_option :full, negatable: true
        flag_option :strict
        flag_option :lost_found
        flag_option :dangling, negatable: true
        flag_option :connectivity_only
        flag_option :name_objects, negatable: true
        flag_option :references, negatable: true
        operand :object, repeatable: true
      end

      # git fsck uses exit codes 0-7 to indicate different levels of issues found
      # Exit code 0 = no issues, 1-7 = various issue types (still considered successful)
      allow_exit_status 0..7

      # Execute the git fsck command
      #
      # @overload call(*object, **options)
      #
      #   @example Check repository integrity
      #     # git fsck --no-progress
      #     result = fsck.call
      #
      #   @example Check specific objects
      #     # git fsck --no-progress abc1234 def5678
      #     result = fsck.call('abc1234', 'def5678')
      #
      #   @example With options
      #     # git fsck --no-progress --unreachable --strict
      #     result = fsck.call(unreachable: true, strict: true)
      #
      #   @param object [Array<String>] optional object identifiers to check
      #
      #   @param options [Hash] command options
      #
      #   @option options [Boolean] :tags (nil) report tags
      #
      #   @option options [Boolean] :root (nil) report root nodes
      #
      #   @option options [Boolean] :unreachable (nil) print out objects that exist but are not
      #     reachable from any of the reference nodes
      #
      #   @option options [Boolean] :cache (nil) consider any object recorded in the index also
      #     as a head node for reachability
      #
      #   @option options [Boolean] :no_reflogs (nil) do not consider commits referenced only by
      #     reflogs to be reachable
      #
      #   @option options [Boolean] :full (nil) check all objects, not just reachable ones. Pass
      #     false to explicitly disable
      #
      #   @option options [Boolean] :strict (nil) enable more strict checking
      #
      #   @option options [Boolean] :lost_found (nil) write dangling objects into .git/lost-found
      #
      #   @option options [Boolean] :dangling (nil) report dangling objects. Pass false to suppress
      #     dangling object reporting
      #
      #   @option options [Boolean] :connectivity_only (nil) check only the connectivity of objects
      #
      #   @option options [Boolean] :name_objects (nil) show the name of each reachable object
      #     alongside its identifier. Pass false to explicitly disable
      #
      #   @option options [Boolean] :references (nil) check reference objects. Pass false to
      #     explicitly disable reference checking
      #
      # @return [Git::CommandLineResult] the result of calling `git fsck`
      #
      # @raise [Git::FailedError] if git returns an exit code > 7
      #
      def call(...) = super # rubocop:disable Lint/UselessMethodDefinition
    end
  end
end
