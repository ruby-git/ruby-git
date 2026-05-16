# frozen_string_literal: true

require 'fileutils'
require 'git/commands/archive'
require 'git/commands/cat_file/raw'
require 'git/commands/grep'
require 'git/commands/ls_tree'
require 'git/commands/name_rev'
require 'git/commands/rev_parse'
require 'git/repository/shared_private'
require 'git/escaped_path'
require 'tempfile'
require 'zlib'

module Git
  class Repository
    # Facade methods for raw git object store queries
    #
    # Included by {Git::Repository}.
    #
    # @api public
    #
    module ObjectOperations
      # Returns the raw content of a git object, or streams it into a tempfile
      #
      # Without a block, the full content is buffered in memory and returned as a
      # `String`. With a block, git output is streamed directly to disk without
      # memory buffering — safe for large blobs.
      #
      # @overload cat_file_contents(object)
      #   Returns the object's raw content as a string
      #
      #   @example Get the contents of a blob
      #     repo.cat_file_contents('HEAD:README.md') # => "This is a README file\n"
      #
      #   @param object [String] the object name (SHA, ref, `HEAD`, treeish path, etc.)
      #
      #   @return [String] the raw content of the object
      #
      # @overload cat_file_contents(object, &block)
      #   Streams the object's raw content to a temporary file and yields it
      #
      #   Git output is written directly to a file on disk without being buffered in
      #   memory first, then the file is rewound and yielded to the block. The return
      #   value is whatever the block returns.
      #
      #   @example Read a large blob without buffering it in memory
      #     repo.cat_file_contents('HEAD:large_file.bin') { |f| process(f) }
      #
      #   @param object [String] the object name (SHA, ref, `HEAD`, treeish path, etc.)
      #
      #   @yield [file] the temporary file containing the streamed content,
      #     positioned at the start
      #
      #   @yieldparam file [File] readable `IO` object positioned at the beginning
      #     of the content
      #
      #   @yieldreturn [Object] the value to return from this method
      #
      #   @return [Object] the value returned by the block
      #
      # @raise [ArgumentError] if `object` starts with a hyphen
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @see https://git-scm.com/docs/git-cat-file git-cat-file documentation
      #
      def cat_file_contents(object)
        raise ArgumentError, "Invalid object: '#{object}'" if object&.start_with?('-')

        return Git::Commands::CatFile::Raw.new(@execution_context).call(object, p: true).stdout unless block_given?

        # Stream git output directly to a tempfile to avoid buffering large
        # object content in memory when a block is given.
        Tempfile.create do |file|
          file.binmode
          Git::Commands::CatFile::Raw.new(@execution_context).call(object, p: true, out: file)
          file.rewind
          yield file
        end
      end

      # Returns the size of a git object in bytes
      #
      # @example Get the size of a commit object
      #   repo.cat_file_size('HEAD') #=> 265
      #
      # @example Get the size of a blob by treeish path
      #   repo.cat_file_size('HEAD:README.md') #=> 14
      #
      # @param object [String] the object name (SHA, ref, `HEAD`, treeish path, etc.)
      #
      # @return [Integer] the object size in bytes
      #
      # @raise [ArgumentError] if `object` starts with a hyphen
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @see https://git-scm.com/docs/git-cat-file git-cat-file documentation
      #
      def cat_file_size(object)
        raise ArgumentError, "Invalid object: '#{object}'" if object&.start_with?('-')

        Git::Commands::CatFile::Raw.new(@execution_context).call(object, s: true).stdout.chomp.to_i
      end

      # Returns the type of a git object
      #
      # @example Get the type of a commit reference
      #   repo.cat_file_type('HEAD') #=> "commit"
      #
      # @example Get the type of a blob via treeish path
      #   repo.cat_file_type('HEAD:README.md') #=> "blob"
      #
      # @param object [String] the object name (SHA, ref, `HEAD`, treeish path, etc.)
      #
      # @return [String] the object type — one of `"blob"`, `"commit"`,
      #   `"tag"`, or `"tree"`
      #
      # @raise [ArgumentError] if `object` starts with a hyphen
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @see https://git-scm.com/docs/git-cat-file git-cat-file documentation
      #
      def cat_file_type(object)
        raise ArgumentError, "Invalid object: '#{object}'" if object&.start_with?('-')

        Git::Commands::CatFile::Raw.new(@execution_context).call(object, t: true).stdout.chomp
      end

      # Returns parsed commit data for the given git object
      #
      # @example Get commit data for HEAD
      #   repo.cat_file_commit('HEAD')
      #   # => {
      #   #   'sha'       => 'HEAD',
      #   #   'tree'      => 'def5678...',
      #   #   'parent'    => ['ghi9012...'],
      #   #   'author'    => 'A U Thor <author@example.com> 1234567890 +0000',
      #   #   'committer' => 'A U Thor <author@example.com> 1234567890 +0000',
      #   #   'message'   => "Initial commit\n"
      #   # }
      #
      # @param object [String] the object name (SHA, ref, `HEAD`, etc.)
      #
      # @return [Hash] commit data
      #
      #   String-keyed hash with the following keys:
      #
      #   * `tree` — the tree SHA
      #   * `parent` — Array of parent SHAs (empty for the root commit)
      #   * `author` — author identity string and timestamp
      #   * `committer` — committer identity string and timestamp
      #   * `message` — the commit message (includes trailing newline)
      #   * `gpgsig` — the cryptographic signature (signed commits only)
      #   * `sha` — the `object` argument as passed by the caller
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @see https://git-scm.com/docs/git-cat-file git-cat-file documentation
      #
      def cat_file_commit(object)
        result = Git::Commands::CatFile::Raw.new(@execution_context).call('commit', object)
        Private.process_commit_data(result.stdout.split("\n"), object)
      end

      # Returns parsed tag data for the given annotated tag object
      #
      # Does not work with lightweight tags. To list all annotated tags in a
      # repository:
      #
      # ```sh
      # git for-each-ref --format='%(refname:strip=2)' refs/tags | \
      #   while read tag; do
      #     git cat-file tag "$tag" >/dev/null 2>&1 && echo "$tag"
      #   done
      # ```
      #
      # @example Get tag data for an annotated tag
      #   repo.cat_file_tag('v1.0')
      #   # => {
      #   #   'name'    => 'v1.0',
      #   #   'object'  => 'abc1234...',
      #   #   'type'    => 'commit',
      #   #   'tag'     => 'v1.0',
      #   #   'tagger'  => 'A U Thor <author@example.com> 1234567890 +0000',
      #   #   'message' => "Release v1.0\n"
      #   # }
      #
      # @param object [String] the annotated tag name or SHA
      #
      # @return [Hash] tag data
      #
      #   String-keyed hash with the following keys:
      #
      #   * `name` — the `object` argument as passed by the caller
      #   * `object` — the SHA of the tagged object
      #   * `type` — the type of the tagged object (usually `"commit"`)
      #   * `tag` — the tag name
      #   * `tagger` — tagger identity string and timestamp
      #   * `message` — the tag message (includes trailing newline)
      #
      # @raise [ArgumentError] if `object` starts with a hyphen
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @see https://git-scm.com/docs/git-cat-file git-cat-file documentation
      #
      def cat_file_tag(object)
        raise ArgumentError, "Invalid object: '#{object}'" if object&.start_with?('-')

        tdata = Git::Commands::CatFile::Raw.new(@execution_context).call('tag', object).stdout.split("\n")
        Private.process_tag_data(tdata, object)
      end

      # Resolve a revision specifier to its full object ID
      #
      # Passes the given revision specifier to `git rev-parse` and returns the
      # full object ID.
      #
      # @example Resolve HEAD to its full object ID
      #   repo.rev_parse('HEAD') #=> "9b9b31e704c0b85ffdd8d2af2ded85170a5af87d"
      #
      # @example Resolve an abbreviated SHA
      #   repo.rev_parse('9b9b31e') #=> "9b9b31e704c0b85ffdd8d2af2ded85170a5af87d"
      #
      # @example Resolve a tree object via rev-parse syntax
      #   repo.rev_parse('HEAD^{tree}') #=> "94c827875e2cadb8bc8d4cdd900f19aa9e8634c7"
      #
      # @param objectish [String] the revision specifier to resolve (branch name,
      #   tag, abbreviated SHA, refspec, etc.)
      #
      # @return [String] the full object ID of the resolved object
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @see https://git-scm.com/docs/git-rev-parse git-rev-parse documentation
      #
      # @see https://git-scm.com/docs/git-rev-parse#_specifying_revisions Valid ways to specify revisions
      #
      def rev_parse(objectish)
        Git::Commands::RevParse.new(@execution_context).call(objectish, '--', revs_only: true).stdout
      end

      # Returns all recursive entries for a given tree object
      #
      # Equivalent to running `git ls-tree -r <objectish>` and splitting the
      # output on newlines. Each returned line describes a single entry in the
      # tree in the format produced by `git ls-tree`: `<mode> <type> <object>\t<file>`.
      #
      # @example List all files in the tree rooted at HEAD
      #   repo.full_tree('HEAD^{tree}')
      #   # => [
      #   #   "100644 blob e69de29bb2d1d6434b8b29ae775ad8c2e48c5391\tex_dir/ex.txt",
      #   #   "100644 blob abc1234...\tlib/git.rb"
      #   # ]
      #
      # @param objectish [String] the tree SHA or tree-ish specifier to recurse
      #   into
      #
      # @return [Array<String>] one entry per path, in the format
      #   `<mode> <type> <object>\t<file>`
      #
      #   Returns an empty array for an empty tree.
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @see https://git-scm.com/docs/git-ls-tree git-ls-tree documentation
      #
      def full_tree(objectish)
        Git::Commands::LsTree.new(@execution_context).call(objectish, r: true).stdout.split("\n")
      end

      # Returns the number of entries in a tree
      #
      # Runs `git ls-tree -r <objectish>` and counts output lines.
      # This matches `Git::Lib#tree_depth` behavior in the 4.x branch.
      #
      # @example Count entries in the tree rooted at HEAD
      #   repo.tree_depth('HEAD^{tree}') #=> 42
      #
      # @param objectish [String] the tree SHA or tree-ish specifier to recurse
      #   into
      #
      # @return [Integer] the number of entries in the recursive tree listing
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @see https://git-scm.com/docs/git-ls-tree git-ls-tree documentation
      #
      def tree_depth(objectish)
        Git::Commands::LsTree.new(@execution_context).call(objectish, r: true).stdout.each_line.count
      end

      # Find the first symbolic name for a commit-ish
      #
      # @example Find the symbolic name for a commit
      #   repo.name_rev('abc123') #=> "main~5"
      #
      # @example Find the symbolic name for HEAD
      #   repo.name_rev('HEAD') #=> "main"
      #
      # @param commit_ish [String] the commit-ish to find the symbolic name of
      #
      # @return [String, nil] the first symbolic name, or nil if stdout contains
      #   fewer than two words
      #
      # @raise [ArgumentError] if commit_ish starts with a hyphen
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @see https://git-scm.com/docs/git-name-rev git-name-rev documentation
      #
      def name_rev(commit_ish)
        raise ArgumentError, "Invalid commit_ish: '#{commit_ish}'" if commit_ish&.start_with?('-')

        Git::Commands::NameRev.new(@execution_context).call(commit_ish).stdout.split[1]
      end

      # Option keys accepted by {#ls_tree}
      LS_TREE_ALLOWED_OPTS = %i[recursive path].freeze
      private_constant :LS_TREE_ALLOWED_OPTS

      # List the objects in a git tree
      #
      # Runs `git ls-tree` against the given sha and returns a Hash of tree
      # entries organised by object type.
      #
      # @example List the top-level tree
      #   repo.ls_tree('HEAD')
      #   # => { 'blob' => { 'README.md' => { mode: '100644', sha: 'abc...' } },
      #   #      'tree' => { 'lib' => { mode: '040000', sha: 'def...' } },
      #   #      'commit' => {} }
      #
      # @example List the tree recursively
      #   repo.ls_tree('HEAD', recursive: true)
      #   # => { 'blob' => { 'lib/git.rb' => { mode: '100644', sha: '...' } }, ... }
      #
      # @example Limit the listing to a path
      #   repo.ls_tree('HEAD', path: 'lib/')
      #
      # @param objectish [String] the tree-ish object to list
      #
      # @param opts [Hash] additional options
      #
      # @option opts [Boolean, nil] :recursive (nil) recurse into subtrees
      #
      # @option opts [String, Array<String>] :path (nil) path or array of paths
      #   to limit the listing to
      #
      # @return [Hash<String, Hash<String, Hash>>] a three-level Hash keyed by
      #   object type (`'blob'`, `'tree'`, `'commit'`), then by filename, then
      #   holding `:mode` and `:sha` values
      #
      # @raise [ArgumentError] when unsupported options are provided
      #
      # @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      # @see https://git-scm.com/docs/git-ls-tree git-ls-tree documentation
      #
      def ls_tree(objectish, opts = {})
        SharedPrivate.assert_valid_opts!(LS_TREE_ALLOWED_OPTS, **opts)
        paths = Array(opts[:path]).compact
        r_value = opts[:recursive]
        safe_options = {}
        safe_options[:r] = r_value unless r_value.nil?
        result = Git::Commands::LsTree.new(@execution_context).call(objectish, *paths, **safe_options)
        Private.parse_ls_tree_output(result.stdout)
      end

      # Option keys accepted by {#grep}
      GREP_ALLOWED_OPTS = %i[ignore_case i invert_match v extended_regexp E object].freeze
      private_constant :GREP_ALLOWED_OPTS

      # Search tracked file contents in a git tree for a pattern
      #
      # Runs `git grep` against the given tree-ish and returns every match as a
      # filename-keyed hash of `[line_number, text]` pairs.
      #
      # @example Search HEAD for a pattern
      #   repo.grep('TODO')
      #   # => { "HEAD:src/foo.rb" => [[12, "# TODO: fix this"]], ... }
      #
      # @example Limit the search to a path
      #   repo.grep('TODO', 'src/')
      #
      # @example Search a specific commit
      #   repo.grep('TODO', nil, object: 'abc1234')
      #
      # @example Case-insensitive search
      #   repo.grep('todo', nil, ignore_case: true)
      #
      # @param pattern [String] the pattern to search for
      #
      # @param path_limiter [String, Pathname, Array<String, Pathname>, nil]
      #   a path or array of paths to limit the search to, or `nil` for no limit
      #
      # @param opts [Hash] additional options for the grep command
      #
      # @option opts [String] :object ('HEAD') the tree-ish to search
      #
      # @option opts [Boolean, nil] :ignore_case (nil) ignore case
      #   distinctions in both the pattern and the file contents
      #
      #   Alias: :i
      #
      # @option opts [Boolean, nil] :invert_match (nil) select non-matching
      #   lines
      #
      #   Alias: :v
      #
      # @option opts [Boolean, nil] :extended_regexp (nil) use POSIX extended
      #   regular expressions for the pattern
      #
      #   Alias: :E
      #
      # @return [Hash<String, Array<Array(Integer, String)>>] a hash mapping
      #   each `"treeish:filename"` key to an array of `[line_number, text]`
      #   pairs; returns an empty hash when no lines match
      #
      # @raise [ArgumentError] if unsupported options are provided
      #
      # @raise [Git::FailedError] if git exits with a non-zero status and
      #   stderr is non-empty (e.g. bad object reference)
      #
      # @see https://git-scm.com/docs/git-grep git-grep documentation
      #
      def grep(pattern, path_limiter = nil, opts = {})
        SharedPrivate.assert_valid_opts!(GREP_ALLOWED_OPTS, **opts)
        opts = opts.dup
        object = opts.delete(:object) || 'HEAD'
        opts[:pathspec] = Array(path_limiter).map(&:to_s) if path_limiter
        result = Git::Commands::Grep.new(@execution_context).call(
          object, pattern:, **opts, no_color: true, line_number: true
        )
        Private.process_grep_result(result)
      end

      # Option keys accepted by {#archive}
      ARCHIVE_ALLOWED_OPTS = %i[prefix remote path format add_gzip].freeze
      private_constant :ARCHIVE_ALLOWED_OPTS

      # Create an archive of the repository tree and write it to a file
      #
      # Writes the archive content to a file and returns the file path. The
      # default format is `zip`. Pass `format: 'tar'` for an uncompressed tar
      # archive, or `format: 'tgz'` for a gzip-compressed tar archive
      # (equivalent to `format: 'tar'` with `add_gzip: true`).
      #
      # When no `file` path is given, a temporary file is created and its path
      # is returned.
      #
      # **File replacement behavior when `file` is given:**
      #
      # The archive is first written to a staging file in the same directory as
      # `file`. This means write permission is required on the parent directory
      # of `file`, not just on `file` itself. Once the archive is fully written,
      # the staging file atomically replaces `file` via rename.
      #
      # If `file` already exists, only its numeric permission bits are applied to
      # the new archive; ownership, ACLs, and extended attributes are not
      # transferred. If `file` does not exist, the archive receives the standard
      # file creation mode (`0666 & ~umask`). On Windows, `File.chmod` has no
      # effect, so the archive always receives the default creation mode
      # regardless of whether `file` already exists.
      #
      # If `file` is a symlink that does not point to a directory, the symlink
      # itself is replaced by the new archive file rather than writing through
      # the link to its target. A symlink that points to a directory is treated
      # as a directory and rejected with `ArgumentError`.
      #
      # @example Archive HEAD as a zip file
      #   repo.archive('HEAD', '/tmp/release.zip') #=> "/tmp/release.zip"
      #
      # @example Archive a tag as a tar file
      #   repo.archive('v1.0', '/tmp/release.tar', format: 'tar') #=> "/tmp/release.tar"
      #
      # @example Archive with a path prefix applied to every entry
      #   repo.archive('HEAD', '/tmp/out.tar', format: 'tar', prefix: 'myproject/')
      #   #=> "/tmp/out.tar"
      #
      # @example Archive a subdirectory only
      #   repo.archive('HEAD', '/tmp/src.tar', format: 'tar', path: 'src/')
      #   #=> "/tmp/src.tar"
      #
      # @param treeish [String] tree-ish to archive — commit SHA, tag, branch
      #   name, or tree SHA
      #
      # @param file [String, nil] (nil) destination file path; when `nil`, a
      #   unique temporary file is created and its path is returned
      #
      # @param opts [Hash] archive options
      #
      # @option opts [String] :format ('zip') archive format — `'tar'`, `'zip'`,
      #   or `'tgz'`; `'tgz'` is internally converted to `'tar'` with gzip
      #   post-processing
      #
      # @option opts [String] :prefix (nil) prefix prepended to every filename
      #   in the archive; typically ends with `/`
      #
      # @option opts [String] :path (nil) path within the tree to include in the
      #   archive; when given, only files under that path are archived
      #
      # @option opts [String] :remote (nil) retrieve the archive from a remote
      #   repository rather than the local one
      #
      # @option opts [Boolean, nil] :add_gzip (nil) apply gzip compression after
      #   writing the archive; set automatically when `format: 'tgz'` is given
      #
      # @return [String] path to the written archive file
      #
      # @raise [ArgumentError] if unsupported options are provided
      #
      # @raise [ArgumentError] if `file` is an existing directory
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @see https://git-scm.com/docs/git-archive git-archive documentation
      #
      def archive(treeish, file = nil, opts = {})
        SharedPrivate.assert_valid_opts!(ARCHIVE_ALLOWED_OPTS, **opts)
        raise ArgumentError, "#{file.inspect} is a directory" if file && File.directory?(file)

        tmp = Private.write_archive_tmp(@execution_context, treeish, opts, dest_dir: Private.staging_dir_for(file))
        return tmp unless file

        Private.atomic_replace(tmp, file)
        file
      rescue StandardError
        FileUtils.rm_f(tmp) if tmp
        raise
      end

      # Private helpers for {#cat_file_commit}, {#cat_file_tag}, {#grep},
      # {#ls_tree}, and {#archive}
      #
      # @api private
      #
      # rubocop:disable Metrics/ModuleLength
      module Private
        module_function

        # Matches a single `git cat-file` header line
        #
        # @api private
        #
        CAT_FILE_HEADER_LINE = /\A(?<key>\w+) (?<value>.*)\z/

        # Interprets a `Git::Commands::Grep` result and returns parsed matches
        #
        # Exit status 1 with empty stderr means no lines matched — returns `{}`.
        # Exit status 1 with non-empty stderr is a real error and raises.
        # Exit status 0 parses the output lines.
        #
        # @param result [Git::CommandLineResult] the result from the grep command
        #
        # @return [Hash<String, Array<Array(Integer, String)>>] parsed match hash
        #
        # @raise [Git::FailedError] if exit status is 1 and stderr is non-empty
        #
        # @api private
        #
        def process_grep_result(result)
          exitstatus = result.status.exitstatus
          return {} if exitstatus == 1 && result.stderr.empty?

          raise Git::FailedError, result if exitstatus == 1

          parse_grep_output(result.stdout.split("\n"))
        end

        # Parses `git grep` output lines into a filename-keyed hash of matches
        #
        # Each line is expected in the format produced by
        # `git grep --line-number --no-color`: `treeish:filename:linenum:text`.
        #
        # @param lines [Array<String>] output lines from `git grep`
        #
        # @return [Hash<String, Array<Array(Integer, String)>>] hash mapping
        #   `"treeish:filename"` keys to arrays of `[line_number, text]` pairs
        #
        # @api private
        #
        def parse_grep_output(lines)
          lines.each_with_object(Hash.new { |h, k| h[k] = [] }) do |line, hsh|
            match = line.match(/\A(.*?):(\d+):(.*)/)
            next unless match

            _full, filename, line_num, text = match.to_a
            hsh[filename] << [line_num.to_i, text]
          end
        end

        # Resolve the staging directory for a git archive temp file
        #
        # Always returns `Dir.tmpdir` when `file` is nil, or the parent
        # directory of `file` otherwise. Staging the temp file in the same
        # directory as the destination keeps both paths on the same filesystem
        # so that {#atomic_replace} can use an atomic rename that
        # requires no extra disk space.
        #
        # @param file [String, nil] the explicit destination path, or nil
        #
        # @return [String] directory path to pass to `Tempfile.create`
        #
        # @api private
        #
        def staging_dir_for(file)
          return Dir.tmpdir unless file

          File.dirname(File.expand_path(file))
        end

        # Write a git archive to a fresh temporary file and return its path
        #
        # Always writes to a new temporary file so that on error the caller's
        # destination file is never truncated. Format and gzip post-processing
        # are determined from `opts` via {#parse_archive_format_options}.
        #
        # @param execution_context [Git::ExecutionContext] for the git command
        # @param treeish [String] tree-ish passed to `git archive`
        # @param opts [Hash] caller-supplied options (read-only)
        # @param dest_dir [String] directory for the staging temp file; use
        #   {#staging_dir_for} to select the optimal directory for the destination
        #
        # @return [String] path to the populated temporary file
        #
        # @api private
        #
        def write_archive_tmp(execution_context, treeish, opts, dest_dir: Dir.tmpdir)
          format, gzip = parse_archive_format_options(opts)
          tmp_file = create_archive_tempfile(execution_context, treeish, opts, format, dest_dir)
          apply_gzip(tmp_file.path) if gzip
          tmp_file.path
        rescue StandardError
          tmp_file.close unless tmp_file.nil? || tmp_file.closed?
          FileUtils.rm_f(tmp_file.path) if tmp_file
          raise
        end

        # Create a staging file, write the archive into it, close it, and return it
        #
        # Uses `Tempfile.create` (not `Tempfile.new`) so that no GC finalizer is
        # registered on the returned object — the file path remains valid after this
        # method returns and after the caller stores only the path string.
        #
        # @param execution_context [Git::ExecutionContext] for the git command
        # @param treeish [String] tree-ish passed to `git archive`
        # @param opts [Hash] caller-supplied options (read-only; used for :prefix,
        #   :remote, and :path)
        # @param format [String] archive format string (e.g. `'zip'` or `'tar'`)
        # @param dest_dir [String] directory in which to create the temp file
        #
        # @return [File] the closed file containing the archive
        #
        # @api private
        #
        def create_archive_tempfile(execution_context, treeish, opts, format, dest_dir)
          tmp_file = Tempfile.create('archive', dest_dir).tap(&:binmode)
          run_archive_command(execution_context, treeish, opts, format, tmp_file)
          tmp_file.close
          tmp_file
        rescue StandardError
          tmp_file&.close
          FileUtils.rm_f(tmp_file.path) if tmp_file
          raise
        end

        # Invoke `git archive` and stream output into `tmp_file`
        #
        # @param execution_context [Git::ExecutionContext] for the git command
        # @param treeish [String] tree-ish passed to `git archive`
        # @param opts [Hash] caller-supplied options (read-only; used for :prefix,
        #   :remote, and :path)
        # @param format [String] archive format to pass to `git archive --format`
        # @param tmp_file [File] open, binary-mode IO to write archive data to
        #
        # @return [Git::CommandLineResult] the result of the git command
        #
        # @api private
        #
        def run_archive_command(execution_context, treeish, opts, format, tmp_file)
          command_opts = opts.slice(:prefix, :remote).merge(format: format)
          path_args = opts[:path] ? [opts[:path]] : []
          Git::Commands::Archive.new(execution_context).call(treeish, *path_args, **command_opts, out: tmp_file)
        end

        # Atomically rename the staging file `src` to `dest`, replacing any
        # existing file at `dest`. Both paths must be on the same filesystem
        # (guaranteed when `src` is created by {#staging_dir_for}).
        #
        # Before the rename, the staging file's permissions are set to the
        # existing file's numeric mode (if `dest` already existed) or to
        # `0666 & ~umask` (standard creation mode) for new files. The chmod
        # is applied to `src` before the rename so that, if chmod fails, `src`
        # is still present and can be cleaned up by the rescue. Only the
        # numeric permission bits are carried over; ownership, ACLs, and
        # extended attributes from an existing `dest` are not preserved.
        #
        # If `dest` is a symlink, the symlink itself is replaced by the renamed
        # staging file rather than writing through the link to its target.
        #
        # @param src [String] staging file path to rename; removed on success
        # @param dest [String] destination file path
        #
        # @return [void]
        #
        # @api private
        #
        def atomic_replace(src, dest)
          mode = File.exist?(dest) ? (File.stat(dest).mode & 0o777) : (0o666 & ~File.umask)
          File.chmod(mode, src)
          File.rename(src, dest)
        rescue StandardError
          FileUtils.rm_f(src)
          raise
        end

        # Determine the archive format and whether to apply gzip post-processing
        #
        # The `tgz` pseudo-format is not understood by `git archive` directly;
        # it is converted to `tar` and the gzip flag is set so that {#archive}
        # applies gzip compression after the archive is written.
        #
        # @param opts [Hash] caller-supplied options hash (read-only)
        #
        # @return [Array(String, Boolean)] a two-element array `[format, gzip]`
        #
        #   `format` is the string to pass to `git archive --format`; `gzip` is
        #   `true` when the caller should apply gzip post-processing after writing
        #   the archive.
        #
        # @api private
        #
        def parse_archive_format_options(opts)
          format = opts[:format] || 'zip'
          gzip = opts[:add_gzip] == true || format == 'tgz'
          [format == 'tgz' ? 'tar' : format, gzip]
        end

        # Apply gzip compression to the given file in place
        #
        # Streams from the source file through a {Zlib::GzipWriter} into a sibling
        # temporary file, then replaces the original.  Peak memory is proportional
        # to the stream buffer rather than the full archive size.
        #
        # @param file [String] path to the file to compress in place
        #
        # @return [void]
        #
        # @api private
        #
        def apply_gzip(file)
          gz_tmp = Tempfile.create('archive_gz', File.dirname(file)).tap(&:close).path
          Zlib::GzipWriter.open(gz_tmp) { |gz| File.open(file, 'rb') { |f| IO.copy_stream(f, gz) } }
          FileUtils.rm_f(file)
          File.rename(gz_tmp, file)
        rescue StandardError
          FileUtils.rm_f(gz_tmp) if gz_tmp
          raise
        end

        # Assembles the commit Hash from parsed lines
        #
        # @param data [Array<String>] mutable cat-file output lines, consumed
        #   in place during header parsing
        #
        # @param sha [String] the object name passed by the caller
        #
        # @return [Hash] commit data hash with string keys
        #
        # @api private
        #
        def process_commit_data(data, sha)
          headers = process_commit_headers(data)
          message = "#{data.join("\n")}\n"
          { 'sha' => sha, 'message' => message }.merge(headers)
        end

        # Extracts and returns headers from the front of `data`
        #
        # Mutates `data` in place, consuming header lines and the blank
        # separator line. After the call `data` contains only message lines.
        #
        # @param data [Array<String>] mutable cat-file output lines
        #
        # @return [Hash] parsed header key/value pairs; `parent` is always
        #   an Array
        #
        # @api private
        #
        def process_commit_headers(data)
          headers = { 'parent' => [] }
          each_cat_file_header(data) do |key, value|
            if key == 'parent'
              headers['parent'] << value
            else
              headers[key] = value
            end
          end
          headers
        end

        # Assembles the tag Hash from parsed lines
        #
        # @param data [Array<String>] mutable cat-file output lines, consumed
        #   in place during header parsing; remaining lines become the message
        #
        # @param name [String] the tag name passed by the caller
        #
        # @return [Hash] tag data hash with string keys
        #
        # @api private
        #
        def process_tag_data(data, name)
          hsh = { 'name' => name }
          each_cat_file_header(data) { |key, value| hsh[key] = value }
          hsh['message'] = "#{data.join("\n")}\n"
          hsh
        end

        # Yields parsed header key/value pairs from `git cat-file` output lines
        #
        # Consumes header lines from the front of `data` until a blank line is
        # encountered. Continuation lines that begin with a space are folded
        # into the previous header value using newline separators.
        #
        # @param data [Array<String>] mutable output lines from a cat-file response
        #
        # @yield [key, value] each parsed header pair
        #
        # @yieldparam key [String] header field name
        #
        # @yieldparam value [String] unfolded header value text
        #
        # @yieldreturn [void]
        #
        # @return [void]
        #
        # @raise [NoMethodError] if `data` contains non-string entries
        #
        # @api private
        #
        def each_cat_file_header(data)
          while (line = data.shift) && (match = CAT_FILE_HEADER_LINE.match(line))
            key = match[:key]
            value_lines = [match[:value]]
            value_lines << data.shift.lstrip while data.first&.start_with?(' ')
            yield key, value_lines.join("\n")
          end
        end

        # Parses `git ls-tree` output into a type-keyed hash of entries
        #
        # Each line of output is expected in the format produced by
        # `git ls-tree`: `<mode> <type> <sha>\t<file>`.
        #
        # @param output [String] raw stdout from `git ls-tree`
        #
        # @return [Hash<String, Hash<String, Hash>>] hash keyed by object type
        #   (`'blob'`, `'tree'`, `'commit'`), then by filename, holding
        #   `:mode` and `:sha` values
        #
        # @api private
        #
        def parse_ls_tree_output(output)
          data = { 'blob' => {}, 'tree' => {}, 'commit' => {} }
          output.split("\n").each do |line|
            info, filenm = line.split("\t", 2)
            filenm = unescape_quoted_path(filenm) if filenm
            mode, type, entry_sha = info.split
            data[type][filenm] = { mode: mode, sha: entry_sha }
          end
          data
        end

        # Converts a git-quoted path back to its original form
        #
        # @param path [String] the path, possibly git-quoted
        #
        # @return [String] the unquoted path
        #
        # @api private
        #
        def unescape_quoted_path(path)
          if path.start_with?('"') && path.end_with?('"')
            Git::EscapedPath.new(path[1..-2]).unescape
          else
            path
          end
        end
      end
      # rubocop:enable Metrics/ModuleLength
      private_constant :Private
    end
  end
end
