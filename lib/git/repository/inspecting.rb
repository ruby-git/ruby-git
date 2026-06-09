# frozen_string_literal: true

require 'git/commands/describe'
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
      # Give a human-readable name to a commit based on the most recent reachable tag
      #
      # Runs `git describe` to find the nearest tag reachable from `committish` and
      # formats a version string. When the tag points directly at the commit, only the
      # tag name is shown. Otherwise, the tag name is suffixed with the number of
      # additional commits and the abbreviated commit SHA (e.g. `v1.0.0-3-gabcdef1`).
      #
      # @example Describe HEAD
      #   repo.describe #=> "v1.0.0"
      #
      # @example Describe a specific commit
      #   repo.describe('abc123') #=> "v1.0.0-3-gabcdef1"
      #
      # @example Describe using any tag (not just annotated tags)
      #   repo.describe(nil, tags: true) #=> "v1.0.0-lightweight"
      #
      # @example Require an exact tag match
      #   repo.describe(nil, exact_match: true)
      #
      # @example Use the legacy hyphenated key (still accepted)
      #   repo.describe(nil, :'exact-match' => true)
      #
      # @param committish [String, nil] the commit-ish to describe; defaults to HEAD
      #   when `nil`
      #
      # @param opts [Hash] options forwarded to `git describe`
      #
      # @option opts [Boolean, nil] :all (nil) use any ref in `refs/`, not just tags
      #
      # @option opts [Boolean, nil] :tags (nil) use lightweight tags as well as
      #   annotated ones
      #
      # @option opts [Boolean, nil] :contains (nil) describe the tag that contains the
      #   commit, rather than the nearest reachable one
      #
      # @option opts [Boolean, String, nil] :abbrev (nil) number of hex digits for the
      #   abbreviated object name; `true` uses git's default length
      #
      # @option opts [Boolean, String, nil] :dirty (nil) append a dirty-state mark to
      #   the description; `true` appends `-dirty`, a String appends that string
      #
      # @option opts [Boolean, String, nil] :broken (nil) like `:dirty` but treats
      #   broken repository links as dirty
      #
      # @option opts [Integer, String, nil] :candidates (nil) number of candidate tags
      #   to consider; increasing above 10 may yield a more accurate result
      #
      # @option opts [Boolean, nil] :exact_match (nil) only succeed when the commit is
      #   pointed to by a tag directly (no suffix)
      #
      #   The legacy hyphenated key `:"exact-match"` is also accepted and is
      #   automatically translated to `:exact_match`.
      #
      # @option opts [Boolean, nil] :debug (nil) verbosely display the search strategy
      #
      # @option opts [Boolean, nil] :long (nil) always output the long format even when
      #   the commit matches a tag exactly
      #
      # @option opts [String, Array<String>, nil] :match (nil) only consider tags
      #   matching the given `glob(7)` pattern; pass an array for multiple patterns
      #
      # @option opts [String, Array<String>, nil] :exclude (nil) do not consider tags
      #   matching the given `glob(7)` pattern; pass an array for multiple patterns
      #
      # @option opts [Boolean, nil] :always (nil) show the abbreviated commit SHA as
      #   fallback when the commit cannot be described
      #
      # @option opts [Boolean, nil] :first_parent (nil) follow only the first parent of
      #   merge commits when searching for the nearest tag
      #
      # @return [String] the human-readable description of the commit, with trailing
      #   newlines preserved
      #
      # @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      # @raise [ArgumentError] when `committish` looks like a command-line flag (starts
      #   with `-`), or when `opts` contains any key not in the documented option list
      #
      def describe(committish = nil, opts = {})
        raise ArgumentError, "Invalid commit-ish object: '#{committish}'" if committish&.start_with?('-')

        opts = opts.dup
        if opts.key?(:'exact-match')
          opts[:exact_match] ||= opts[:'exact-match']
          opts.delete(:'exact-match')
        end
        SharedPrivate.assert_valid_opts!(DESCRIBE_ALLOWED_OPTS, **opts)
        commit_ishes = Array(committish).compact
        Git::Commands::Describe.new(@execution_context).call(*commit_ishes, **opts).stdout
      end

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

      # Option keys accepted by {#describe}
      DESCRIBE_ALLOWED_OPTS = %i[
        all tags contains abbrev dirty broken candidates
        exact_match debug long match exclude always first_parent
      ].freeze
      private_constant :DESCRIBE_ALLOWED_OPTS

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
