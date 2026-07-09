# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git fsck` command
    #
    # Verifies the connectivity and validity of objects in the database.
    # It checks the integrity of the repository, reporting any dangling, missing, or
    # unreachable objects.
    #
    # @example Typical usage
    #   fsck = Git::Commands::Fsck.new(execution_context)
    #   fsck.call
    #   fsck.call('abc1234', 'def5678')
    #   fsck.call(unreachable: true, strict: true)
    #   fsck.call(no_dangling: true)
    #
    # @note `arguments` block audited against https://git-scm.com/docs/git-fsck/2.53.0
    #
    # @see https://git-scm.com/docs/git-fsck git-fsck
    #
    # @see Git::Commands
    #
    # @api private
    #
    class Fsck < Git::Commands::Base
      arguments do
        literal 'fsck'
        flag_option :progress, negatable: true

        # Ref reporting
        flag_option :tags
        flag_option :root
        flag_option :unreachable
        flag_option :cache
        flag_option :no_reflogs

        # Checking scope
        flag_option :full, negatable: true
        flag_option :strict
        flag_option :verbose
        flag_option :lost_found

        # Output control
        flag_option :dangling, negatable: true
        flag_option :connectivity_only
        flag_option :name_objects, negatable: true
        flag_option :references, negatable: true

        operand :object, repeatable: true
      end

      # git fsck uses exit codes 0-7 as bit flags for findings
      allow_exit_status 0..7

      # @overload call(*object, **options)
      #
      #     Execute the `git fsck` command
      #
      #     @param object [Array<String>] zero or more object identifiers to check
      #
      #       When none are given, git fsck defaults to using the index file and
      #       all references as heads.
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean, nil] :tags (nil) report tags
      #
      #     @option options [Boolean, nil] :root (nil) report root nodes
      #
      #     @option options [Boolean, nil] :unreachable (nil) print out objects that
      #       exist but are not reachable from any of the reference nodes
      #
      #     @option options [Boolean, nil] :cache (nil) consider any object recorded
      #       in the index also as a head node for reachability
      #
      #     @option options [Boolean, nil] :no_reflogs (nil) do not consider commits
      #       referenced only by reflogs to be reachable
      #
      #     @option options [Boolean, nil] :full (nil) check not just objects in
      #       `GIT_OBJECT_DIRECTORY` but also those in alternate object pools and
      #       packed archives (`--full`)
      #
      #     @option options [Boolean, nil] :no_full (nil) skip checking alternate object
      #       pools and packed archives (`--no-full`)
      #
      #     @option options [Boolean, nil] :strict (nil) enable more strict checking,
      #       catching files with `g+w` bits set
      #
      #     @option options [Boolean, nil] :verbose (nil) be chatty
      #
      #     @option options [Boolean, nil] :lost_found (nil) write dangling objects
      #       into `.git/lost-found/commit/` or `.git/lost-found/other/`
      #
      #     @option options [Boolean, nil] :dangling (nil) print dangling objects (`--dangling`)
      #
      #     @option options [Boolean, nil] :no_dangling (nil) suppress dangling object
      #       reporting (`--no-dangling`)
      #
      #     @option options [Boolean, nil] :progress (nil) show progress status on
      #       standard error (`--progress`)
      #
      #     @option options [Boolean, nil] :no_progress (nil) suppress progress output
      #       when attached to a terminal (`--no-progress`)
      #
      #     @option options [Boolean, nil] :connectivity_only (nil) check only the
      #       connectivity of reachable objects; faster but does not validate
      #       blob content
      #
      #     @option options [Boolean, nil] :name_objects (nil) show the name of each
      #       reachable object alongside its identifier (`--name-objects`)
      #
      #     @option options [Boolean, nil] :no_name_objects (nil) suppress object name
      #       display (`--no-name-objects`)
      #
      #     @option options [Boolean, nil] :references (nil) check reference database
      #       consistency via `git refs verify` (`--references`)
      #
      #     @option options [Boolean, nil] :no_references (nil) skip reference checking
      #       (`--no-references`)
      #
      #     @return [Git::CommandLine::Result] the result of calling `git fsck`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if git exits outside the allowed range
      #       (exit code > 7)
      #
      #     @api public
      #
      def call(*, **)
        super
      end
    end
  end
end
