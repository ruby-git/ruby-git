# frozen_string_literal: true

require 'git/commands/cat_file/raw'
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
      # @return [String] the object type — one of `"blob"`, `"commit"`, `"tag"`, or `"tree"`
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

      # Private parsing helpers for {#cat_file_commit}
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
          while (match = CAT_FILE_HEADER_LINE.match(data.shift))
            key = match[:key]
            value_lines = [match[:value]]
            value_lines << data.shift.lstrip while data.first.start_with?(' ')
            yield key, value_lines.join("\n")
          end
        end
      end
      private_constant :Private
    end
  end
end
