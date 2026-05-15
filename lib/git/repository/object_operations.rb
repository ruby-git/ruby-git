# frozen_string_literal: true

require 'git/commands/cat_file/raw'
require 'git/commands/grep'
require 'git/commands/rev_parse'
require 'git/repository/shared_private'
require 'tempfile'

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

      # Private parsing helpers for {#cat_file_commit}, {#cat_file_tag}, and
      # {#grep}
      #
      # @api private
      #
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
          each_cat_file_header(data) do |key, value|
            hsh[key] = value
          end
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
      end
      private_constant :Private
    end
  end
end
