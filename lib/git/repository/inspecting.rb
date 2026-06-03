# frozen_string_literal: true

require 'git/commands/fsck'
require 'git/commands/show'
require 'git/parsers/fsck'
require 'git/repository/shared_private'

module Git
  class Repository
    # Facade methods for read-only repository inspection operations
    #
    # These methods report on the contents and integrity of the repository.
    #
    # Included by {Git::Repository}.
    #
    # @api public
    #
    module Inspecting
      # Show a single git object (a commit, tag, tree, or blob)
      #
      # @example Show the HEAD commit
      #   repo.show
      #
      # @example Show a specific commit
      #   repo.show('HEAD~1')
      #
      # @example Show the contents of a file at a revision
      #   repo.show('HEAD', 'README.md')
      #
      # @param objectish [String, nil] the object to show; a ref, SHA, or
      #   `objectish:path` expression
      #
      #   Defaults to `HEAD` when `nil`.
      #
      # @param path [String, nil] the file whose contents to show at `objectish`,
      #   when given
      #
      #   Combined with `objectish` as `objectish:path`. When `objectish` is `nil`
      #   and `path` is given, `HEAD` is used as the objectish, so
      #   `show(nil, 'README.md')` resolves to `HEAD:README.md`.
      #
      # @return [String] git's stdout from the show, with trailing newlines
      #   preserved
      #
      # @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      def show(objectish = nil, path = nil)
        object = path ? "#{objectish || 'HEAD'}:#{path}" : objectish
        Git::Commands::Show.new(@execution_context).call(*[object].compact).stdout
      end

      # Option keys accepted by {#fsck}
      #
      # `:progress`/`:no_progress` are intentionally excluded: progress output is
      # always suppressed (see {#fsck}), so callers may not toggle it.
      FSCK_ALLOWED_OPTS = %i[
        tags root unreachable cache no_reflogs
        full no_full strict verbose lost_found dangling no_dangling
        connectivity_only name_objects no_name_objects references no_references
      ].freeze
      private_constant :FSCK_ALLOWED_OPTS

      # Verify the connectivity and validity of the objects in the database
      #
      # Runs `git fsck` and returns the categorized objects it flags. Progress
      # output is always suppressed (`--no-progress`) so that stdout contains only
      # the machine-parsable findings.
      #
      # @overload fsck(*objects, **options)
      #
      #   @example Check repository integrity
      #     result = repo.fsck
      #     result.dangling.each { |obj| puts "#{obj.type}: #{obj.oid}" }
      #
      #   @example Check if the repository is clean
      #     repo.fsck.empty? #=> true
      #
      #   @example List root commits
      #     repo.fsck(root: true).root.each { |obj| puts obj.oid }
      #
      #   @example Check specific objects
      #     repo.fsck('abc1234', 'def5678')
      #
      #   @param objects [Array<String>] specific objects to treat as heads for the
      #     unreachability trace
      #
      #     When none are given, git fsck defaults to the index file, all refs, and
      #     all reflogs.
      #
      #   @param options [Hash] options for the fsck command
      #
      #   @option options [Boolean, nil] :tags (nil) report tags
      #
      #   @option options [Boolean, nil] :root (nil) report root nodes
      #
      #   @option options [Boolean, nil] :unreachable (nil) print objects that exist
      #     but are not reachable from any reference node
      #
      #   @option options [Boolean, nil] :cache (nil) consider objects recorded in the
      #     index as head nodes for reachability
      #
      #   @option options [Boolean, nil] :no_reflogs (nil) do not consider commits
      #     referenced only by reflogs to be reachable
      #
      #   @option options [Boolean, nil] :full (nil) also check alternate object
      #     pools and packed archives, not just the local store
      #
      #   @option options [Boolean, nil] :no_full (nil) skip alternate object pools and
      #     packed archives
      #
      #   @option options [Boolean, nil] :strict (nil) enable stricter checking
      #
      #   @option options [Boolean, nil] :verbose (nil) be chatty
      #
      #   @option options [Boolean, nil] :lost_found (nil) write dangling objects
      #     into `.git/lost-found`
      #
      #     This modifies the repository by creating files.
      #
      #   @option options [Boolean, nil] :dangling (nil) print dangling objects
      #
      #   @option options [Boolean, nil] :no_dangling (nil) suppress dangling object
      #     reporting
      #
      #   @option options [Boolean, nil] :connectivity_only (nil) check only
      #     connectivity; faster but does not validate blob content
      #
      #   @option options [Boolean, nil] :name_objects (nil) show the name of each
      #     reachable object alongside its identifier
      #
      #   @option options [Boolean, nil] :no_name_objects (nil) suppress object name
      #     display
      #
      #   @option options [Boolean, nil] :references (nil) check reference database
      #     consistency
      #
      #   @option options [Boolean, nil] :no_references (nil) skip reference checking
      #
      #   @return [Git::FsckResult] the objects flagged by fsck, categorized by status
      #
      #   @raise [ArgumentError] when unsupported options are provided
      #
      #   @raise [Git::FailedError] when git exits outside the allowed range (exit
      #     code > 7)
      #
      def fsck(*objects, **)
        SharedPrivate.assert_valid_opts!(FSCK_ALLOWED_OPTS, **)
        result = Git::Commands::Fsck.new(@execution_context).call(*objects, **, no_progress: true)
        Git::Parsers::Fsck.parse(result.stdout)
      end
    end
  end
end
