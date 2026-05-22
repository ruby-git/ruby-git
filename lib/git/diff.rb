# frozen_string_literal: true

require_relative 'diff_path_status'
require_relative 'diff_stats'

module Git
  # Diff between two commits or between a commit and the working tree
  #
  # @example Diff between two commits
  #   diff = repo.diff('HEAD~1', 'HEAD')
  #   diff.size       # => 3
  #   diff.insertions # => 20
  #   diff.deletions  # => 5
  #
  # @example Limit diff to a specific path
  #   diff = repo.diff('HEAD~1', 'HEAD').path('lib/')
  #
  # @api public
  #
  class Diff
    include Enumerable

    # Creates a new Diff
    #
    # @example
    #   diff = Git::Diff.new(base, 'HEAD~1', 'HEAD')
    #
    # @param base [Git::Base, Git::Repository] the git repository
    #
    # @param from [String, nil] the starting commit ref, or `nil` to compare
    #   from the index
    #
    # @param to [String, nil] the ending commit ref, or `nil` to compare to
    #   the working tree
    #
    # @return [void]
    #
    def initialize(base, from = nil, to = nil)
      @base = base
      @from = from&.to_s
      @to = to&.to_s

      @path = nil
      @full_diff_files = nil
    end

    # The starting commit ref
    #
    # @return [String, nil] the starting commit ref, or `nil` if not set
    #
    attr_reader :from

    # The ending commit ref
    #
    # @return [String, nil] the ending commit ref, or `nil` if not set
    #
    attr_reader :to

    # Limits the diff to the specified path(s)
    #
    # When called with no arguments (or only nil arguments), removes any existing
    # path filter, showing all files in the diff. Internally stores a single path
    # as a String and multiple paths as an Array for efficiency.
    #
    # @example Limit diff to a single path
    #   git.diff('HEAD~3', 'HEAD').path('lib/')
    #
    # @example Limit diff to multiple paths
    #   git.diff('HEAD~3', 'HEAD').path('src/', 'docs/', 'README.md')
    #
    # @example Remove path filtering (show all files)
    #   diff.path  # or diff.path(nil)
    #
    # @param paths [String, Pathname] one or more paths to filter the diff;
    #   pass no arguments to remove filtering
    #
    # @return [self] returns self for method chaining
    #
    # @raise [ArgumentError] if any path is an Array (use splatted arguments instead)
    #
    def path(*paths)
      validate_paths_not_arrays(paths)

      cleaned_paths = paths.compact

      @path = if cleaned_paths.empty?
                nil
              elsif cleaned_paths.length == 1
                cleaned_paths.first
              else
                cleaned_paths
              end

      self
    end

    # Returns the full diff output as a string
    #
    # @example
    #   diff.patch # => "diff --git a/file.rb b/file.rb\n..."
    #
    # @return [String] the raw output of `git diff`
    #
    def patch
      if @base.respond_to?(:diff_full)
        @base.diff_full(@from, @to, path_limiter: @path)
      else
        @base.lib.diff_full(@from, @to, { path_limiter: @path })
      end
    end
    alias to_s patch

    # Returns the diff file info for the given path
    #
    # @example
    #   diff['lib/git.rb'] # => #<Git::Diff::DiffFile ...>
    #
    # @param key [String] the file path to look up
    #
    # @return [Git::Diff::DiffFile] the diff file object for the given path
    #
    def [](key)
      process_full
      @full_diff_files.assoc(key)[1]
    end

    # Iterates over each changed file in the diff
    #
    # @overload each
    #   @example Get an enumerator
    #     diff.each.map(&:path) # => ["lib/git.rb", "README.md"]
    #
    #   @return [Enumerator<Git::Diff::DiffFile>] an enumerator over the
    #     changed files
    #
    # @overload each(&block)
    #   @example Iterate with a block
    #     diff.each { |file| puts file.path }
    #
    #   @yield [file] each changed file in the diff
    #
    #   @yieldparam file [Git::Diff::DiffFile] a changed file
    #
    #   @yieldreturn [void]
    #
    #   @return [Array<Git::Diff::DiffFile>] the array of changed files
    #
    def each(&)
      process_full
      @full_diff_files.map { |file| file[1] }.each(&)
    end

    # Returns the number of changed files in the diff
    #
    # @example
    #   diff.size # => 3
    #
    # @return [Integer] the number of changed files
    #
    def size
      stats_provider.total[:files]
    end

    #
    # DEPRECATED METHODS
    #

    # Returns the path-to-status hash for all changed files in the diff
    #
    # @example
    #   diff.name_status # => { "lib/git.rb" => "M", "README.md" => "A" }
    #
    # @return [Hash<String, String>] map of file path to git status letter
    #
    def name_status
      path_status_provider.to_h
    end

    # Returns the total number of changed lines in the diff
    #
    # @example
    #   diff.lines # => 42
    #
    # @return [Integer] the total number of inserted and deleted lines
    #
    def lines
      stats_provider.lines
    end

    # Returns the total number of deleted lines in the diff
    #
    # @example
    #   diff.deletions # => 10
    #
    # @return [Integer] the number of deleted lines
    #
    def deletions
      stats_provider.deletions
    end

    # Returns the total number of inserted lines in the diff
    #
    # @example
    #   diff.insertions # => 32
    #
    # @return [Integer] the number of inserted lines
    #
    def insertions
      stats_provider.insertions
    end

    # Returns a statistics hash for the diff
    #
    # @example
    #   diff.stats
    #   # => {
    #   #   files: { "lib/git.rb" => { insertions: 5, deletions: 2 } },
    #   #   total: { insertions: 5, deletions: 2, lines: 7 }
    #   # }
    #
    # @return [Hash] statistics including per-file and total insert/delete counts
    #
    def stats
      {
        files: stats_provider.files,
        total: stats_provider.total
      }
    end

    # Information about a single changed file within a {Git::Diff}
    #
    # @example Access diff file information
    #   diff.each do |file|
    #     puts file.path
    #     puts file.binary? ? 'binary' : file.patch
    #   end
    #
    # @api public
    #
    class DiffFile
      # The raw diff patch text for this file
      #
      # @return [String, nil] the patch text
      #
      attr_accessor :patch

      # The file path relative to the repository root
      #
      # @return [String, nil] the file path
      #
      attr_accessor :path

      # The file mode
      #
      # @return [String] the octal file mode (e.g. `"100644"`)
      #
      attr_accessor :mode

      # The source (pre-change) blob SHA
      #
      # @return [String] the source blob SHA
      #
      attr_accessor :src

      # The destination (post-change) blob SHA
      #
      # @return [String] the destination blob SHA
      #
      attr_accessor :dst

      # The type of change
      #
      # @return [String] the change type (e.g. `"modified"`, `"new"`, `"deleted"`)
      #
      attr_accessor :type

      @base = nil

      # Regexp matching a nil blob SHA (all-zero hash of 4 to 40 hex digits)
      NIL_BLOB_REGEXP = /\A0{4,40}\z/

      # Creates a new DiffFile from parsed diff data
      #
      # @example
      #   file = Git::Diff::DiffFile.new(base,
      #     patch: "diff --git ...", path: 'lib/git.rb',
      #     mode: '100644', src: 'abc123', dst: 'def456',
      #     type: 'modified', binary: false)
      #
      # @param base [Git::Base, Git::Repository] the git repository
      #
      # @param hash [Hash] the parsed diff attributes
      #
      # @return [void]
      #
      def initialize(base, hash)
        @base = base
        @patch = hash[:patch]
        @path = hash[:path]
        @mode = hash[:mode]
        @src = hash[:src]
        @dst = hash[:dst]
        @type = hash[:type]
        @binary = hash[:binary]
      end

      # Returns true if this file is a binary file
      #
      # @example
      #   diff['path/to/image.png'].binary? # => true
      #
      # @return [Boolean] `true` if the file is binary, `false` otherwise
      #
      def binary?
        !!@binary
      end

      # Returns the blob object for this file
      #
      # @example Retrieve the destination blob
      #   file.blob       # => #<Git::Object::Blob ...>
      #
      # @example Retrieve the source blob
      #   file.blob(:src) # => #<Git::Object::Blob ...>
      #
      # @param type [Symbol] `:src` to retrieve the source blob, or `:dst`
      #   (default) for the destination blob
      #
      # @return [Git::Object::Blob, nil] the blob object, or `nil` if the blob
      #   SHA is the null SHA
      #
      def blob(type = :dst)
        if type == :src && !NIL_BLOB_REGEXP.match(@src)
          @base.object(@src)
        elsif !NIL_BLOB_REGEXP.match(@dst)
          @base.object(@dst)
        end
      end
    end

    private

    # Validates that no path argument is an Array
    #
    # @param paths [Array] the raw paths array passed to {#path}
    #
    # @return [void]
    #
    # @raise [ArgumentError] if any element of paths is an Array
    #
    def validate_paths_not_arrays(paths)
      return unless paths.any?(Array)

      raise ArgumentError,
            'path expects individual arguments, not arrays. ' \
            "Use path('lib/', 'docs/') not path(['lib/', 'docs/'])"
    end

    # Triggers full diff processing if not yet done
    #
    # @return [void]
    #
    def process_full
      return if @full_diff_files

      @full_diff_files = process_full_diff
    end

    # Returns a memoized DiffPathStatus provider for this diff
    #
    # @return [Git::DiffPathStatus] the path status provider
    #
    def path_status_provider
      @path_status_provider ||= Git::DiffPathStatus.new(@base, @from, @to, @path)
    end

    # Returns a memoized DiffStats provider for this diff
    #
    # @return [Git::DiffStats] the stats provider
    #
    def stats_provider
      @stats_provider ||= Git::DiffStats.new(@base, @from, @to, @path)
    end

    # Parses the full diff output into DiffFile objects
    #
    # @return [Array<Array(String, Git::Diff::DiffFile)>] list of
    #   `[filename, DiffFile]` pairs
    #
    def process_full_diff
      FullDiffParser.new(@base, patch).parse
    end

    # Private parser for `git diff` output
    #
    # @example Parse a diff patch
    #   parser = Git::Diff::FullDiffParser.new(base, patch_text)
    #   files = parser.parse
    #
    # @api private
    #
    class FullDiffParser
      # Creates a new FullDiffParser
      #
      # @param base [Git::Base, Git::Repository] the git repository
      #
      # @param patch_text [String] the raw `git diff` output to parse
      #
      # @return [void]
      #
      def initialize(base, patch_text)
        @base = base
        @patch_text = patch_text
        @final_files = {}
        @current_file_data = nil
        @defaults = { mode: '', src: '', dst: '', type: 'modified', binary: false }
      end

      # Parses the diff text into a list of filename/DiffFile pairs
      #
      # @return [Array<Array(String, Git::Diff::DiffFile)>] list of
      #   `[filename, DiffFile]` pairs
      #
      def parse
        @patch_text.split("\n").each { |line| process_line(line) }
        @final_files.map { |filename, data| [filename, DiffFile.new(@base, data)] }
      end

      private

      # Dispatches a single diff line to the appropriate handler
      #
      # @param line [String] a line from the diff output
      #
      # @return [void]
      #
      def process_line(line)
        if (new_file_match = line.match(%r{\Adiff --git ("?)a/(.+?)\1 ("?)b/(.+?)\3\z}))
          start_new_file(new_file_match, line)
        else
          append_to_current_file(line)
        end
      end

      # Starts tracking a new file from a diff header line
      #
      # @param match [MatchData] the regex match from the diff header line
      #
      # @param line [String] the original diff header line
      #
      # @return [void]
      #
      def start_new_file(match, line)
        filename = Git::EscapedPath.new(match[2]).unescape
        @current_file_data = @defaults.merge({ patch: line, path: filename })
        @final_files[filename] = @current_file_data
      end

      # Appends a diff line to the current file's accumulated data
      #
      # @param line [String] a diff line to append
      #
      # @return [void]
      #
      def append_to_current_file(line)
        return unless @current_file_data

        parse_index_line(line)
        parse_file_mode_line(line)
        check_for_binary(line)

        @current_file_data[:patch] << "\n#{line}"
      end

      # Parses an index line to extract source and destination blob SHAs
      #
      # @param line [String] a diff line that may be an index line
      #
      # @return [void]
      #
      def parse_index_line(line)
        return unless (match = line.match(/^index ([0-9a-f]{4,40})\.\.([0-9a-f]{4,40})( ......)*/))

        @current_file_data[:src] = match[1]
        @current_file_data[:dst] = match[2]
        @current_file_data[:mode] = match[3].strip if match[3]
      end

      # Parses a file mode line to extract the change type and file mode
      #
      # @param line [String] a diff line that may be a file mode line
      #
      # @return [void]
      #
      def parse_file_mode_line(line)
        return unless (match = line.match(/^([[:alpha:]]*?) file mode (......)/))

        @current_file_data[:type] = match[1]
        @current_file_data[:mode] = match[2]
      end

      # Marks the current file as binary if this is a binary diff line
      #
      # @param line [String] a diff line to check for the binary file marker
      #
      # @return [void]
      #
      def check_for_binary(line)
        @current_file_data[:binary] = true if line.match?(/^Binary files /)
      end
    end
  end
end
