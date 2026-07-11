# frozen_string_literal: true

module Git
  # The Status class gets the status of a git repository. It identifies which
  # files have been modified, added, or deleted, including untracked files.
  # The Status object is an Enumerable of StatusFile objects.
  #
  # @example Inspect repository status
  #   repo = Git.open('/path/to/repo')
  #   status = repo.status
  #   status.changed.each { |path, _file| puts "Modified: #{path}" }
  #   status.added.each { |path, _file| puts "Added: #{path}" }
  #   status.deleted.each { |path, _file| puts "Deleted: #{path}" }
  #   status.untracked.each { |path, _file| puts "Untracked: #{path}" }
  #
  # @api public
  #
  class Status
    include Enumerable

    # Create a new Status for the given repository
    #
    # @param base [Git::Repository] the git object backing this status
    #
    def initialize(base)
      @base = base
      # The factory returns a hash of file paths to StatusFile objects.
      @files = StatusFileFactory.new(base).construct_files
    end

    # Return files modified in the index and/or working tree
    #
    # Includes both staged modifications (index vs HEAD) and unstaged modifications
    # (working tree vs index).
    #
    # @return [Hash{String => Git::Status::StatusFile}] changed files keyed by path
    #
    def changed   = @changed ||= select_files { |f| f.type == 'M' }

    # Return files added to the index that are not yet in HEAD
    #
    # @return [Hash{String => Git::Status::StatusFile}] added files keyed by path
    #
    def added     = @added ||= select_files { |f| f.type == 'A' }

    # Return files deleted from the index
    #
    # @return [Hash{String => Git::Status::StatusFile}] deleted files keyed by path
    #
    def deleted   = @deleted ||= select_files { |f| f.type == 'D' }

    # Return files present in the working tree but not tracked by git
    #
    # @return [Hash{String => Git::Status::StatusFile}] untracked files keyed by path
    #
    def untracked = @untracked ||= select_files(&:untracked)

    # Return `true` if `file` has been modified in the index or working tree
    #
    # @param file [String] the repository-relative path to check
    #
    # @return [Boolean] `true` if the file has been modified
    #
    def changed?(file)   = file_in_collection?(:changed, file)

    # Return `true` if `file` has been added to the index
    #
    # @param file [String] the repository-relative path to check
    #
    # @return [Boolean] `true` if the file has been added
    #
    def added?(file)     = file_in_collection?(:added, file)

    # Return `true` if `file` has been deleted from the index
    #
    # @param file [String] the repository-relative path to check
    #
    # @return [Boolean] `true` if the file has been deleted
    #
    def deleted?(file)   = file_in_collection?(:deleted, file)

    # Return `true` if `file` is not tracked by git
    #
    # @param file [String] the repository-relative path to check
    #
    # @return [Boolean] `true` if the file is untracked
    #
    def untracked?(file) = file_in_collection?(:untracked, file)

    # Return the {Git::Status::StatusFile} for the given path
    #
    # @param file [String] the repository-relative path
    #
    # @return [Git::Status::StatusFile, nil] the status file, or `nil` if not found
    #
    def [](file) = @files[file]

    # Iterate over all status files
    #
    # @overload each
    #
    #   @return [Enumerator<Git::Status::StatusFile>] an enumerator over all status files
    #
    # @overload each(&block)
    #
    #   @return [Array<Git::Status::StatusFile>] the full list of status files
    #
    #   @yield [file] each {Git::Status::StatusFile} in the repository
    #
    #   @yieldparam file [Git::Status::StatusFile] a single file's status
    #
    #   @yieldreturn [void]
    #
    def each(&) = @files.values.each(&)

    # Return a formatted multi-line string representation of the status
    #
    # @return [String] one indented block per file showing its SHA, mode, type,
    #   stage, and untracked flag
    #
    def pretty
      map { |file| pretty_file(file) }.join << "\n"
    end

    private

    # Format a single file's status as an indented multi-line string
    #
    # @param file [Git::Status::StatusFile] the file to format
    #
    # @return [String] the formatted status block for this file
    #
    def pretty_file(file)
      <<~FILE
        #{file.path}
        \tsha(r) #{file.sha_repo} #{file.mode_repo}
        \tsha(i) #{file.sha_index} #{file.mode_index}
        \ttype   #{file.type}
        \tstage  #{file.stage}
        \tuntrac #{file.untracked}
      FILE
    end

    # Return a hash of files for which the block returns a truthy value
    #
    # @return [Hash{String => Git::Status::StatusFile}] matching files keyed by path
    #
    # @yield [file] each {Git::Status::StatusFile} in the repository
    #
    # @yieldparam file [Git::Status::StatusFile] a single file's status
    #
    # @yieldreturn [Boolean] truthy to include the file in the result
    #
    def select_files(&block)
      @files.select { |_path, file| block.call(file) }
    end

    # Return `true` if `file_path` exists in the named status collection
    #
    # @param collection_name [Symbol] the collection to check (e.g. `:changed`)
    #
    # @param file_path [String] the repository-relative path to look up
    #
    # @return [Boolean] `true` if the path is present in the collection
    #
    def file_in_collection?(collection_name, file_path)
      collection = public_send(collection_name)
      if ignore_case?
        downcased_keys(collection_name).include?(file_path.downcase)
      else
        collection.key?(file_path)
      end
    end

    # Return a memoized set of downcased keys for the named collection
    #
    # @param collection_name [Symbol] the collection whose keys to downcase
    #
    # @return [Set<String>] the lowercased path keys
    #
    def downcased_keys(collection_name)
      @_downcased_keys ||= {}
      @_downcased_keys[collection_name] ||=
        public_send(collection_name).keys.to_set(&:downcase)
    end

    # Return `true` when git is configured to ignore filename case
    #
    # Reads `core.ignoreCase` with {Git::Repository#config_get}. Returns `false`
    # when the config value is absent.
    #
    # @return [Boolean] `true` when `core.ignoreCase` is `"true"`
    #
    def ignore_case?
      return @ignore_case if defined?(@ignore_case)

      @ignore_case = (@base.config_get('core.ignoreCase')&.value == 'true')
    end
  end
end

module Git
  class Status
    # Represents a single file's status in the git repository. Each instance
    # holds information about a file's state in the index and working tree.
    #
    # @api public
    #
    class StatusFile
      # The repository-relative file path
      #
      # @return [String] the path
      attr_reader :path

      # The change type for this file
      #
      # @return [String, nil] `"M"` for modified, `"A"` for added, `"D"` for deleted,
      #   or `nil` when not applicable
      attr_reader :type

      # The merge stage for this file
      #
      # @return [String, nil] `"0"` for normal entries, or a non-zero value during
      #   a merge conflict
      attr_reader :stage

      # The file mode recorded in the index
      #
      # @return [String, nil] the octal file mode (e.g. `"100644"`), or `nil`
      attr_reader :mode_index

      # The file mode recorded in HEAD
      #
      # @return [String, nil] the octal file mode (e.g. `"100644"`), or `nil`
      attr_reader :mode_repo

      # The SHA of the index version of this file
      #
      # @return [String, nil] the SHA-1 hex digest, or `nil` if unavailable
      attr_reader :sha_index

      # The SHA of the HEAD version of this file
      #
      # @return [String, nil] the SHA-1 hex digest, or `nil` if unavailable
      attr_reader :sha_repo

      # Whether this file is untracked
      #
      # @return [Boolean, nil] `true` when the file is not tracked by git
      attr_reader :untracked

      # Initialize a new StatusFile with the given git object and data hash
      #
      # @param base [Git::Repository] the git object
      #
      # @param hash [Hash] raw status data for this file
      #
      def initialize(base, hash)
        @base       = base
        @path       = hash[:path]
        @type       = hash[:type]
        @stage      = hash[:stage]
        @mode_index = hash[:mode_index]
        @mode_repo  = hash[:mode_repo]
        @sha_index  = hash[:sha_index]
        @sha_repo   = hash[:sha_repo]
        @untracked  = hash[:untracked]
      end

      # Return a blob object for the index or repo version of this file
      #
      # @param type [Symbol] `:index` (default) for the index version, or
      #   `:repo` for the HEAD version
      #
      # @return [Git::Object::Blob, nil] the blob object, or `nil` if no SHA
      #   is available for the requested version
      #
      def blob(type = :index)
        sha = type == :repo ? sha_repo : (sha_index || sha_repo)
        @base.object(sha) if sha
      end
    end
  end
end

module Git
  class Status
    # A factory class responsible for fetching git status data and building
    # a hash of StatusFile objects.
    #
    # @api private
    #
    class StatusFileFactory
      # Create a new factory backed by the given git object
      #
      # @param base [Git::Repository] the git object used as the status data provider
      #
      def initialize(base)
        @base = base
      end

      # Gather all status data and build a hash of file paths to StatusFile objects
      #
      # @return [Hash{String => Git::Status::StatusFile}] file paths mapped to
      #   their status objects
      #
      def construct_files
        files_data = fetch_all_files_data
        files_data.transform_values do |data|
          StatusFile.new(@base, data)
        end
      end

      private

      # Fetch and merge status information from multiple git commands
      #
      # @return [Hash{String => Hash}] raw per-file status data keyed by path
      #
      def fetch_all_files_data
        files = @base.ls_files # Start with files tracked in the index.
        merge_untracked_files(files)
        merge_modified_files(files)
        merge_head_diffs(files)
        files
      end

      # Merge untracked working-tree files into `files`
      #
      # @param files [Hash] the in-progress files hash to update in place
      #
      # @return [void]
      #
      def merge_untracked_files(files)
        @base.untracked_files.each do |file|
          files[file] = { path: file, untracked: true }
        end
      end

      # Merge index-versus-working-tree diff data into `files`
      #
      # @param files [Hash] the in-progress files hash to update in place
      #
      # @return [void]
      #
      def merge_modified_files(files)
        # Merge changes between the index and the working directory.
        @base.diff_files.each do |path, data|
          (files[path] ||= {}).merge!(data)
        end
      end

      # Merge HEAD-versus-index diff data into `files`, if commits exist
      #
      # @param files [Hash] the in-progress files hash to update in place
      #
      # @return [void]
      #
      def merge_head_diffs(files)
        is_empty = @base.no_commits?
        return if is_empty

        # Merge changes between HEAD and the index.
        @base.diff_index('HEAD').each do |path, data|
          (files[path] ||= {}).merge!(data)
        end
      end
    end
  end
end
