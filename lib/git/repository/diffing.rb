# frozen_string_literal: true

require 'pathname'
require 'git/commands/diff'
require 'git/commands/diff_files'
require 'git/commands/diff_index'
require 'git/commands/status'
require 'git/diff'
require 'git/diff_path_status'
require 'git/diff_stats'
require 'git/escaped_path'
require 'git/repository/shared_private'

module Git
  class Repository
    # Facade methods for comparing commits and trees using `git diff`
    #
    # Included by {Git::Repository}.
    #
    # @api public
    #
    module Diffing
      # Option keys accepted by {#diff_full}
      #
      # @return [Array<Symbol>]
      #
      # @api private
      #
      DIFF_FULL_ALLOWED_OPTS = %i[path_limiter].freeze
      private_constant :DIFF_FULL_ALLOWED_OPTS

      # Returns the full unified diff patch text between two trees
      #
      # Compares (1) two commits, (2) a commit against the working tree, or (3) the
      # index against the working tree using `git diff -p`, and returns the raw
      # unified diff patch output.
      #
      # **Comparing two commits**
      #
      # When both obj1 and obj2 are provided, the comparison is between those two
      # refs (commits, tags, branches, etc.).
      #
      # **Comparing a commit against the working tree**
      #
      # When only obj1 is provided (and isn't nil), the comparison is between obj1 and
      # the working tree; the patch reflects all changes since obj1.
      #
      # **Comparing the index against the working tree**
      #
      # When obj1 is explicitly `nil` then obj2 must be omitted or `nil`. In this case,
      # the comparison is between the index and the working tree; the patch reflects
      # unstaged changes.
      #
      # @example Get the working tree patch since HEAD
      #   repo.diff_full #=> "diff --git a/lib/foo.rb b/lib/foo.rb\n..."
      #
      # @example Compare two specific commits
      #   repo.diff_full('abc1234', 'def5678')
      #
      # @example Get unstaged changes (index vs. working tree)
      #   repo.diff_full(nil)
      #
      # @example Limit the diff to a sub-path
      #   repo.diff_full('HEAD~1', 'HEAD', path_limiter: 'lib/')
      #
      # @param obj1 [String, nil] the first commit or object to compare; defaults to
      #   `'HEAD'`
      #
      # @param obj2 [String, nil] the second commit or object to compare
      #
      # @param opts [Hash] options to filter the diff
      #
      # @option opts [String, Pathname, Array<String, Pathname>, nil] :path_limiter (nil)
      #   limit the diff to the given path(s)
      #
      # @return [String] the unified diff patch output
      #
      # @raise [ArgumentError] if unsupported options are provided
      #
      # @raise [ArgumentError] if `obj1` is `nil` but `obj2` is not OR if `obj1` or `obj2` starts with `"-"`
      #
      # @raise [Git::FailedError] if git exits outside the allowed range (exit code > 2)
      #
      # @see https://git-scm.com/docs/git-diff git-diff documentation
      #
      def diff_full(obj1 = 'HEAD', obj2 = nil, opts = {})
        SharedPrivate.assert_valid_opts!(DIFF_FULL_ALLOWED_OPTS, **opts)
        raise ArgumentError, 'Invalid arguments: obj1 is nil but obj2 is not' if obj1.nil? && !obj2.nil?

        pathspecs = Private.normalize_pathspecs(opts[:path_limiter], 'path limiter')
        result = Git::Commands::Diff.new(@execution_context).call(
          *[obj1, obj2].compact,
          patch: true, numstat: true, shortstat: true,
          src_prefix: 'a/', dst_prefix: 'b/',
          path: pathspecs
        )
        Private.extract_patch_text(result.stdout)
      end

      # Option keys accepted by {#diff_numstat}
      #
      # @return [Array<Symbol>]
      #
      # @api private
      #
      DIFF_NUMSTAT_ALLOWED_OPTS = %i[path_limiter].freeze
      private_constant :DIFF_NUMSTAT_ALLOWED_OPTS

      # Returns per-file insertion/deletion counts and totals between two trees
      #
      # Compares (1) two commits, (2) a commit against the working tree, or (3) the
      # index against the working tree using `git diff --numstat`, and returns a
      # structured hash of per-file insertion and deletion line counts together with
      # aggregate totals.
      #
      # **Comparing two commits**
      #
      # When both obj1 and obj2 are provided, the comparison is between those two
      # refs (commits, tags, branches, etc.).
      #
      # **Comparing a commit against the working tree**
      #
      # When only obj1 is provided (and isn't nil), the comparison is between obj1 and
      # the working tree; the stats reflect all changes since obj1.
      #
      # **Comparing the index against the working tree**
      #
      # When obj1 is explicitly `nil` then obj2 must be omitted or `nil`. In this case,
      # the comparison is between the index and the working tree; the stats reflect
      # unstaged changes.
      #
      # @example Compare two specific commits
      #   repo.diff_numstat('abc1234', 'def5678')
      #
      # @example Get working tree changes since HEAD
      #   repo.diff_numstat
      #   #=> {
      #   #     total: { insertions: 5, deletions: 2, lines: 7, files: 1 },
      #   #     files: { "lib/foo.rb" => { insertions: 5, deletions: 2 } }
      #   #   }
      #
      # @example Get unstaged changes (index vs. working tree)
      #   repo.diff_numstat(nil) #=> { ... }
      #
      # @example Limit the stats to a sub-path
      #   repo.diff_numstat('HEAD~1', 'HEAD', path_limiter: 'lib/')
      #
      # @param obj1 [String, nil] the first commit or object to compare; defaults to
      #   `'HEAD'`
      #
      # @param obj2 [String, nil] the second commit or object to compare
      #
      # @param opts [Hash] options to filter the diff
      #
      # @option opts [String, Pathname, Array<String, Pathname>, nil] :path_limiter (nil)
      #   limit the stats to the given path(s)
      #
      # @return [Hash] per-file insertion and deletion counts plus aggregate totals
      #
      #   ```
      #   {
      #     total: { insertions: Integer, deletions: Integer, lines: Integer, files: Integer },
      #     files: { "path/to/file" => { insertions: Integer, deletions: Integer } }
      #   }
      #   ```
      #
      # @raise [ArgumentError] if unsupported options are provided
      #
      # @raise [ArgumentError] if `obj1` is `nil` but `obj2` is not OR if `obj1` or `obj2` starts with `"-"`
      #
      # @raise [Git::FailedError] if git exits outside the allowed range (exit code > 2)
      #
      # @see https://git-scm.com/docs/git-diff git-diff documentation
      #
      def diff_numstat(obj1 = 'HEAD', obj2 = nil, opts = {})
        SharedPrivate.assert_valid_opts!(DIFF_NUMSTAT_ALLOWED_OPTS, **opts)
        raise ArgumentError, 'Invalid arguments: obj1 is nil but obj2 is not' if obj1.nil? && !obj2.nil?

        pathspecs = Private.normalize_pathspecs(opts[:path_limiter], 'path limiter')
        result = Git::Commands::Diff.new(@execution_context).call(
          *[obj1, obj2].compact,
          numstat: true, shortstat: true, src_prefix: 'a/', dst_prefix: 'b/',
          path: pathspecs
        )
        Private.parse_numstat_output(result.stdout)
      end

      # Option keys accepted by {#diff_stats}
      #
      # @return [Array<Symbol>]
      #
      # @api private
      #
      DIFF_STATS_ALLOWED_OPTS = %i[path_limiter].freeze
      private_constant :DIFF_STATS_ALLOWED_OPTS

      # Returns the stats between two trees as a {Git::DiffStats} object
      #
      # Compares (1) two commits, (2) a commit against the working tree, or (3) the
      # index against the working tree and constructs a lazy {Git::DiffStats} that
      # computes per-file insertion and deletion counts on demand when its accessor
      # methods are called.
      #
      # **Comparing two commits**
      #
      # When both obj1 and obj2 are provided, the comparison is between those two
      # refs (commits, tags, branches, etc.).
      #
      # **Comparing a commit against the working tree**
      #
      # When only obj1 is provided (and isn't nil), the comparison is between obj1 and
      # the working tree; the stats reflect all changes since obj1.
      #
      # **Comparing the index against the working tree**
      #
      # When obj1 is explicitly `nil` then obj2 must be omitted or `nil`. In this case,
      # the comparison is between the index and the working tree; the stats reflect
      # unstaged changes.
      #
      # @example Get working tree stats since HEAD
      #   stats = repo.diff_stats
      #   stats.insertions #=> 3
      #   stats.deletions  #=> 1
      #
      # @example Compare two specific commits
      #   repo.diff_stats('abc1234', 'def5678')
      #
      # @example Get unstaged stats (index vs. working tree)
      #   repo.diff_stats(nil).insertions
      #
      # @example Limit stats to a sub-path
      #   repo.diff_stats('HEAD~1', 'HEAD', path_limiter: 'lib/')
      #
      # @param obj1 [String, nil] the first commit or object to compare; defaults to
      #   `'HEAD'`
      #
      # @param obj2 [String, nil] the second commit or object to compare
      #
      # @param opts [Hash] options to filter the diff
      #
      # @option opts [String, Pathname, Array<String, Pathname>, nil] :path_limiter (nil)
      #   limit the stats to the given path(s)
      #
      # @return [Git::DiffStats] a lazy stats object for the comparison
      #
      # @raise [ArgumentError] if unsupported options are provided
      #
      # @raise [ArgumentError] if `obj1` is `nil` but `obj2` is not OR if `obj1` or `obj2` starts with `"-"`
      #
      # @see #diff_numstat
      #
      # @see https://git-scm.com/docs/git-diff git-diff documentation
      #
      def diff_stats(obj1 = 'HEAD', obj2 = nil, opts = {})
        SharedPrivate.assert_valid_opts!(DIFF_STATS_ALLOWED_OPTS, **opts)
        raise ArgumentError, 'Invalid arguments: obj1 is nil but obj2 is not' if obj1.nil? && !obj2.nil?

        Git::DiffStats.new(self, obj1, obj2, opts[:path_limiter])
      end

      # Returns a lazy {Git::Diff} object for the comparison between two trees
      #
      # Compares (1) two commits, (2) a commit against the working tree, or (3) the
      # index against the working tree. The returned {Git::Diff} is lazy — it does
      # not run any git commands until an accessor method (e.g., {Git::Diff#patch},
      # {Git::Diff#each}) is called.
      #
      # Use {Git::Diff#path} to limit the diff to a sub-path after construction.
      #
      # @example Get the diff since HEAD
      #   diff = repo.diff
      #   diff.patch  #=> "diff --git a/lib/foo.rb ..."
      #
      # @example Compare two specific commits
      #   repo.diff('abc1234', 'def5678').patch
      #
      # @example Limit to a sub-path
      #   repo.diff('HEAD~1', 'HEAD').path('lib/').patch
      #
      # @example Get unstaged changes (index vs. working tree)
      #   repo.diff(nil).patch
      #
      # @param obj1 [String, nil] the first commit or object to compare; defaults to
      #   `'HEAD'`
      #
      # @param obj2 [String, nil] the second commit or object to compare
      #
      # @return [Git::Diff] a lazy diff object for the comparison
      #
      # @see https://git-scm.com/docs/git-diff git-diff documentation
      #
      def diff(obj1 = 'HEAD', obj2 = nil)
        Git::Diff.new(self, obj1, obj2)
      end

      # Option keys accepted by {#diff_path_status}
      #
      # @return [Array<Symbol>]
      #
      # @api private
      #
      DIFF_PATH_STATUS_ALLOWED_OPTS = %i[path_limiter path].freeze
      private_constant :DIFF_PATH_STATUS_ALLOWED_OPTS

      # Returns the file path status between two trees
      #
      # Compares (1) two commits, (2) a commit against the working tree, or (3) the
      # index against the working tree and returns a {Git::DiffPathStatus} enumerating
      # each changed file together with its status code (e.g. `"M"` for modified,
      # `"A"` for added, `"D"` for deleted, `"R100"` for a rename with 100%
      # similarity, etc.).
      #
      # **Comparing two commits**
      #
      # When both from and to are provided, the comparison is between those two
      # refs (commits, tags, branches, etc.).
      #
      # **Comparing a commit against the working tree**
      #
      # When only from is provided (and isn't nil), the comparison is between from and
      # the working tree; the status reflects all changes since from.
      #
      # **Comparing the index against the working tree**
      #
      # When from is explicitly `nil` then to must be omitted or `nil`. In this case,
      # the comparison is between the index and the working tree; the status reflects
      # unstaged changes.
      #
      # @example Get working tree path changes since HEAD
      #   repo.diff_path_status #=> #<Git::DiffPathStatus ...>
      #   repo.diff_path_status.to_h #=> { "README.md" => "M", "lib/foo.rb" => "A" }
      #
      # @example Compare two specific commits
      #   repo.diff_path_status('abc1234', 'def5678').to_h
      #
      # @example Get unstaged path changes (index vs. working tree)
      #   repo.diff_path_status(nil).to_h
      #
      # @example Limit the comparison to a sub-path
      #   repo.diff_path_status('HEAD~1', 'HEAD', path_limiter: 'lib/')
      #
      # @param from [String, nil] the first commit or object to compare; defaults to
      #   `'HEAD'`
      #
      # @param to [String, nil] the second commit or object to compare
      #
      # @param opts [Hash] options to filter the diff
      #
      # @option opts [String, Pathname, Array<String, Pathname>, nil] :path_limiter (nil)
      #   limit the status report to the given path(s)
      #
      # @option opts [String, Pathname, Array<String, Pathname>, nil] :path (nil)
      #   **deprecated** — use `:path_limiter` instead
      #
      # @return [Git::DiffPathStatus] the name-status report for the comparison
      #
      # @raise [ArgumentError] if unsupported options are provided
      #
      # @raise [ArgumentError] if `from` is `nil` but `to` is not OR if `from` or `to` starts with `"-"`
      #
      # @raise [Git::FailedError] if git exits outside the allowed range (exit code > 2)
      #
      # @see https://git-scm.com/docs/git-diff git-diff documentation
      #
      def diff_path_status(from = 'HEAD', to = nil, opts = {})
        SharedPrivate.assert_valid_opts!(DIFF_PATH_STATUS_ALLOWED_OPTS, **opts)
        raise ArgumentError, 'Invalid arguments: `from` is nil but `to` is not' if from.nil? && !to.nil?

        path_limiter = Private.resolve_path_limiter(opts)
        pathspecs = Private.normalize_pathspecs(path_limiter, 'path limiter')

        result = Private.call_diff_command(@execution_context, from, to, pathspecs)
        Git::DiffPathStatus.new(Private.extract_name_status_from_raw(result.stdout))
      end

      # Alias for {#diff_path_status}; provided for backward compatibility
      #
      # @return [Git::DiffPathStatus] the name-status report for the comparison
      #
      # @deprecated Use {#diff_path_status} instead
      #
      # @see #diff_path_status
      alias diff_name_status diff_path_status

      # Compares the index and the working directory
      #
      # Runs `git diff-files` to list files that differ between the index
      # (staging area) and the working directory. These are changes that have
      # been made to tracked files but not yet staged.
      #
      # @example List all files with unstaged changes
      #   repo.diff_files
      #   #=> {
      #   #     "lib/foo.rb" => {
      #   #       mode_index: "100644", mode_repo: "100644",
      #   #       path: "lib/foo.rb", sha_repo: "abc1234",
      #   #       sha_index: "0000000000000000000000000000000000000000",
      #   #       type: "M"
      #   #     }
      #   #   }
      #
      # @return [Hash{String => Hash}] a hash keyed by file path
      #
      #   Each value is a hash with the following keys (note the legacy naming
      #   where `:*_repo` holds index data and `:*_index` holds working tree data):
      #
      #   * `:mode_index` [String] the working tree file mode (legacy name)
      #   * `:mode_repo`  [String] the index (staging area) file mode (legacy name)
      #   * `:path`       [String] the file path
      #   * `:sha_repo`   [String] the SHA of the object in the index (staging area) (legacy name)
      #   * `:sha_index`  [String] the SHA of the object in the working tree; all
      #     zeros when git has not computed the working tree blob SHA (legacy name)
      #   * `:type`       [String] the status code (e.g. `"M"`, `"A"`, `"D"`)
      #
      # @raise [Git::FailedError] if git exits outside the allowed range (exit code > 1)
      #
      # @note The field names in the returned hash are **legacy names** inherited
      #   from `Git::Lib#diff_files` and appear counterintuitive: `:mode_repo`
      #   and `:sha_repo` hold **index (staging area)** values, while
      #   `:mode_index` and `:sha_index` hold **working tree** values.
      #
      # @see https://git-scm.com/docs/git-diff-files git-diff-files documentation
      #
      def diff_files
        Git::Commands::Status.new(@execution_context).call
        Private.parse_diff_files_output(
          Git::Commands::DiffFiles.new(@execution_context).call.stdout
        )
      end

      # Compares the working tree against the given tree object
      #
      # Runs `git diff-index <treeish>` (without `--cached`) to list files that
      # differ between the given tree object (e.g. a commit or `"HEAD"`) and the
      # working tree. The index is refreshed via `git status` first so that cached
      # stat information is up to date.
      #
      # This is equivalent to the 4.x `Git::Lib#diff_index` behavior, which also
      # ran `git diff-index` without `--cached`.
      #
      # @example List all working-tree files that differ from HEAD
      #   repo.diff_index('HEAD')
      #   #=> {
      #   #     "lib/foo.rb" => {
      #   #       mode_index: "100644", mode_repo: "100644",
      #   #       path: "lib/foo.rb", sha_repo: "abc1234",
      #   #       sha_index: "0000000000000000000000000000000000000000",
      #   #       type: "M"
      #   #     }
      #   #   }
      #
      # @param treeish [String] the tree object to compare against (e.g. `'HEAD'`,
      #   a commit SHA, or a tag name)
      #
      # @return [Hash{String => Hash}] a hash keyed by file path
      #
      #   Each value is a hash with the following keys (note the legacy naming
      #   where `:*_repo` holds tree data and `:*_index` holds working tree data):
      #
      #   * `:mode_index` [String] the working tree file mode (legacy name)
      #   * `:mode_repo`  [String] the tree (treeish) file mode (legacy name)
      #   * `:path`       [String] the file path
      #   * `:sha_repo`   [String] the SHA of the object in the tree (treeish) (legacy name)
      #   * `:sha_index`  [String] the SHA of the object in the working tree; all
      #     zeros when git has not yet computed the working tree blob SHA (legacy name)
      #   * `:type`       [String] the status code (e.g. `"M"`, `"A"`, `"D"`)
      #
      # @raise [Git::FailedError] if git exits outside the allowed range (exit code > 1)
      #
      # @note `git diff-index` without `--cached` uses the index as a stat cache:
      #   any file whose index entry differs from the tree is reported as changed,
      #   even when the on-disk working-tree content is byte-for-byte identical to
      #   the tree. A staged change that has been reverted in the working tree will
      #   therefore still appear in the result (because the index still differs from
      #   the tree).
      #
      # @note The field names in the returned hash are **legacy names** inherited
      #   from `Git::Lib#diff_index` and appear counterintuitive: `:mode_repo`
      #   and `:sha_repo` hold **tree (treeish)** values, while `:mode_index` and
      #   `:sha_index` hold **working tree** values.
      #
      # @see https://git-scm.com/docs/git-diff-index git-diff-index documentation
      #
      def diff_index(treeish)
        Git::Commands::Status.new(@execution_context).call
        Private.parse_diff_files_output(
          Git::Commands::DiffIndex.new(@execution_context).call(treeish).stdout
        )
      end

      # Private helpers local to {Git::Repository::Diffing}
      #
      # @api private
      #
      module Private
        module_function

        # Resolves the effective path limiter from the options hash
        #
        # When `:path_limiter` is present it is used directly and no warning is
        # emitted. When only `:path` is present a deprecation warning is emitted
        # and its value is used. Returns `nil` when neither key is present.
        #
        # @param opts [Hash] the options hash from {#diff_path_status}
        #
        # @return [String, Pathname, Array<String, Pathname>, nil]
        #   the effective path limiter
        #
        def resolve_path_limiter(opts)
          if opts.key?(:path_limiter)
            opts[:path_limiter]
          elsif opts.key?(:path)
            Git::Deprecation.warn(
              'Git::Repository#diff_path_status :path option is deprecated. Use :path_limiter instead.'
            )
            opts[:path]
          end
        end

        # Extracts only the patch text from combined diff command output
        #
        # When {Git::Commands::Diff} is called with `patch: true, numstat: true,
        # shortstat: true`, the stdout contains numstat lines, a shortstat summary
        # line, and then the unified patch text starting at `"diff --git "`. This
        # method strips the leading numstat/shortstat lines and returns only the
        # patch portion.
        #
        # @param output [String] combined command output
        #
        # @return [String] only the patch text (may be empty when there are no
        #   changes)
        #
        def extract_patch_text(output)
          match = output.match(/^diff --git /m)
          match ? output[match.begin(0)..] : output
        end

        # Runs git-diff with `--raw` format options and returns the result
        #
        # @param execution_context [Git::ExecutionContext] the execution context
        #   used to run git commands
        #
        # @param from [String] first ref
        #
        # @param to [String, nil] second ref
        #
        # @param pathspecs [Array<String>, nil] path limiters
        #
        # @return [Git::CommandLineResult] the result of calling `git diff`
        #
        def call_diff_command(execution_context, from, to, pathspecs)
          Git::Commands::Diff.new(execution_context).call(
            *[from, to].compact,
            raw: true, numstat: true, shortstat: true,
            src_prefix: 'a/', dst_prefix: 'b/',
            path: pathspecs
          )
        end

        # Normalizes path specifications for Git commands
        #
        # @param pathspecs [String, Pathname, Array<String, Pathname>, nil]
        #   the path(s) to normalize
        #
        # @param arg_name [String] the argument name used in error messages
        #
        # @return [Array<String>, nil] the normalized paths, or `nil` if none are valid
        #
        # @raise [ArgumentError] if any path is not a `String` or `Pathname`
        #
        def normalize_pathspecs(pathspecs, arg_name)
          return nil unless pathspecs

          normalized = Array(pathspecs)
          validate_pathspec_types(normalized, arg_name)

          normalized = normalized.map(&:to_s).reject(&:empty?)
          return nil if normalized.empty?

          normalized
        end

        # Raises an error if any element of `pathspecs` is not a `String` or `Pathname`
        #
        # @param pathspecs [Array] the path elements to validate
        #
        # @param arg_name [String] the argument name used in error messages
        #
        # @return [void]
        #
        # @raise [ArgumentError] if any element is not a `String` or `Pathname`
        #
        def validate_pathspec_types(pathspecs, arg_name)
          return if pathspecs.all? { |p| p.is_a?(String) || p.is_a?(Pathname) }

          raise ArgumentError, "Invalid #{arg_name}: must be a String, Pathname, or Array of Strings/Pathnames"
        end

        # Parses raw `git diff-files` output into a file-keyed hash
        #
        # Each output line has the format:
        #   `:old_mode new_mode old_sha new_sha status\tpath`
        #
        # The leading colon on `old_mode` is stripped when building
        # the `:mode_repo` value.
        #
        # @param stdout [String] raw stdout from {Git::Commands::DiffFiles#call}
        #
        # @return [Hash{String => Hash}] a hash keyed by file path where each
        #   value has keys `:mode_index`, `:mode_repo`, `:path`, `:sha_repo`,
        #   `:sha_index`, and `:type`
        #
        def parse_diff_files_output(stdout)
          stdout.split("\n").each_with_object({}) do |line, memo|
            next if line.empty?

            tab_pos = line.index("\t")
            next unless tab_pos

            path, entry = parse_diff_files_line(line, tab_pos)
            memo[path] = entry
          end
        end

        # Parses a single raw `git diff-files` output line into a path/entry pair
        #
        # @param line [String] a single non-empty line containing a tab character
        #
        # @param tab_pos [Integer] the index of the first tab in the line
        #
        # @return [Array(String, Hash)] two-element array of `[path, entry_hash]`
        #
        def parse_diff_files_line(line, tab_pos)
          path = unescape_quoted_path(line[(tab_pos + 1)..])
          parts = line[0, tab_pos].split
          [path, build_diff_files_entry(path, parts)]
        end

        # Builds a single file-info hash for {#parse_diff_files_output}
        #
        # @param path [String] the file path
        #
        # @param parts [Array<String>] the whitespace-split fields from the info
        #   portion of the diff-files line: `[mode_src, mode_dest, sha_src,
        #   sha_dest, type]`
        #
        # @return [Hash] entry hash with keys `:mode_index`, `:mode_repo`, `:path`,
        #   `:sha_repo`, `:sha_index`, `:type`
        #
        def build_diff_files_entry(path, parts)
          {
            mode_index: parts[1],
            mode_repo: parts[0].to_s[1, 7],
            path: path,
            sha_repo: parts[2],
            sha_index: parts[3],
            type: parts[4]
          }
        end

        # Extracts name-status data from `--raw` diff output lines
        #
        # Raw lines have the format:
        #   :old_mode new_mode old_sha new_sha status\tpath
        # or for renames/copies:
        #   :old_mode new_mode old_sha new_sha Rxx\told_path\tnew_path
        #
        # @param output [String] raw diff output
        #
        # @return [Hash{String => String}] mapping of file paths to status tokens
        #
        def extract_name_status_from_raw(output)
          output.split("\n").each_with_object({}) do |line, memo|
            next unless line.start_with?(':')

            parts = line[1..].split(/\s+/, 5)
            status_and_paths = parts[4].split("\t")
            status = status_and_paths[0]
            path = status_and_paths.length > 2 ? status_and_paths[2] : status_and_paths[1]
            memo[unescape_quoted_path(path)] = status
          end
        end

        # Parses combined `--numstat --shortstat` output into an insertions/deletions hash
        #
        # Strips the trailing shortstat summary line and empty lines, parses the
        # remaining numstat lines, and returns a structured hash with per-file
        # stats and aggregated totals.
        #
        # @param output [String] raw stdout from `git diff --numstat --shortstat`
        #
        # @return [Hash] per-file insertion and deletion counts plus aggregate totals
        #
        #   ```
        #   {
        #     total: { insertions: Integer, deletions: Integer, lines: Integer, files: Integer },
        #     files: { "path/to/file" => { insertions: Integer, deletions: Integer } }
        #   }
        #   ```
        #
        def parse_numstat_output(output)
          file_stats = extract_numstat_lines(output).map { |line| parse_numstat_line(line) }
          { total: build_numstat_totals(file_stats), files: build_numstat_files(file_stats) }
        end

        # Builds the `:total` sub-hash for {#parse_numstat_output}
        #
        # @param file_stats [Array<Hash>] per-file stats from {#parse_numstat_line}
        #
        # @return [Hash] aggregate totals
        #
        #   `{ insertions: Integer, deletions: Integer, lines: Integer, files: Integer }`
        #
        def build_numstat_totals(file_stats)
          insertions = file_stats.sum { |s| s[:insertions] }
          deletions  = file_stats.sum { |s| s[:deletions] }
          { insertions: insertions, deletions: deletions,
            lines: insertions + deletions, files: file_stats.size }
        end

        # Builds the `:files` sub-hash for {#parse_numstat_output}
        #
        # @param file_stats [Array<Hash>] per-file stats from {#parse_numstat_line}
        #
        # @return [Hash{String => Hash}] per-file insertion and deletion counts
        #
        def build_numstat_files(file_stats)
          file_stats.to_h { |s| [s[:filename], s.slice(:insertions, :deletions)] }
        end

        # Filters raw numstat+shortstat output to only the numstat lines
        #
        # @param output [String] combined command output
        #
        # @return [Array<String>] only the numstat lines (no empties, no shortstat line)
        #
        def extract_numstat_lines(output)
          output.split("\n").reject { |l| l.empty? || l.match?(/^\s*\d+\s+files?\s+changed/) }
        end

        # Parses a single `--numstat` line into a stats hash
        #
        # Numstat lines have the format `<insertions>\t<deletions>\t<path>`.
        # Quoted paths (containing non-ASCII or special characters) are unescaped.
        #
        # @param line [String] a single numstat output line
        #
        # @return [Hash] `{ filename: String, insertions: Integer, deletions: Integer }`
        #
        def parse_numstat_line(line)
          insertions_s, deletions_s, filename = line.split("\t", 3)
          { filename: unescape_quoted_path(filename), insertions: insertions_s.to_i, deletions: deletions_s.to_i }
        end

        # Unescapes a git-quoted path (e.g. `"quoted_file_\\342\\230\\240"`)
        #
        # Git quotes paths that contain non-ASCII or special characters by
        # wrapping them in double-quotes and octal-escaping each byte. This
        # method strips the surrounding quotes and delegates unescaping to
        # {Git::EscapedPath}.
        #
        # @param path [String] the path as it appears in git output
        #
        # @return [String] the unescaped path
        #
        def unescape_quoted_path(path)
          if path.start_with?('"') && path.end_with?('"')
            Git::EscapedPath.new(path[1..-2]).unescape
          else
            path
          end
        end
      end

      private_constant :Private
    end
  end
end
