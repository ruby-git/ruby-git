# frozen_string_literal: true

# These would be required by the main `git.rb` file

module Git
  # The Status class gets the status of a git repository. It identifies which
  # files have been modified, added, or deleted, including untracked files.
  # The Status object is an Enumerable of StatusFile objects.
  #
  # @api public
  #
  class Status
    include Enumerable

    # @param base [Git::Base] The base git object
    def initialize(base)
      @base = base
      # The factory returns a hash of file paths to StatusFile objects.
      @files = StatusFileFactory.new(base).construct_files
    end

    # File status collections, memoized for performance.
    def changed   = @changed ||= select_files { |f| f.type == 'M' }
    def added     = @added ||= select_files { |f| f.type == 'A' }
    def deleted   = @deleted ||= select_files { |f| f.type == 'D' }
    # This works with `true` or `nil`
    def untracked = @untracked ||= select_files(&:untracked)

    # Predicate methods to check the status of a specific file.
    def changed?(file)   = file_in_collection?(:changed, file)
    def added?(file)     = file_in_collection?(:added, file)
    def deleted?(file)   = file_in_collection?(:deleted, file)
    def untracked?(file) = file_in_collection?(:untracked, file)

    # Access a status file by path, or iterate over all status files.
    def [](file) = @files[file]
    def each(&) = @files.values.each(&)

    # Returns a formatted string representation of the status.
    def pretty
      map { |file| pretty_file(file) }.join << "\n"
    end

    private

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

    def select_files(&block)
      @files.select { |_path, file| block.call(file) }
    end

    def file_in_collection?(collection_name, file_path)
      collection = public_send(collection_name)
      if ignore_case?
        downcased_keys(collection_name).include?(file_path.downcase)
      else
        collection.key?(file_path)
      end
    end

    def downcased_keys(collection_name)
      @_downcased_keys ||= {}
      @_downcased_keys[collection_name] ||=
        public_send(collection_name).keys.to_set(&:downcase)
    end

    def ignore_case?
      return @_ignore_case if defined?(@_ignore_case)

      @_ignore_case = (@base.config('core.ignoreCase') == 'true')
    rescue Git::FailedError
      @_ignore_case = false
    end
  end
end

module Git
  class Status
    # Represents a single file's status in the git repository. Each instance
    # holds information about a file's state in the index and working tree.
    class StatusFile
      attr_reader :path, :type, :stage, :mode_index, :mode_repo,
                  :sha_index, :sha_repo, :untracked

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

      # Returns a Git::Object::Blob for either the index or repo version of the file.
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
    # @api private
    class StatusFileFactory
      def initialize(base)
        @base = base
        @lib = base.lib
      end

      # Gathers all status data and builds a hash of file paths to
      # StatusFile objects.
      def construct_files
        files_data = fetch_all_files_data
        files_data.transform_values do |data|
          StatusFile.new(@base, data)
        end
      end

      private

      # Fetches and merges status information from multiple git commands.
      def fetch_all_files_data
        files = @lib.ls_files # Start with files tracked in the index.
        merge_untracked_files(files)
        merge_modified_files(files)
        merge_head_diffs(files)
        files
      end

      def merge_untracked_files(files)
        @lib.untracked_files.each do |file|
          files[file] = { path: file, untracked: true }
        end
      end

      def merge_modified_files(files)
        # Merge changes between the index and the working directory.
        @lib.diff_files.each do |path, data|
          (files[path] ||= {}).merge!(data)
        end
      end

      def merge_head_diffs(files)
        return if @lib.empty?

        # Merge changes between HEAD and the index.
        @lib.diff_index('HEAD').each do |path, data|
          (files[path] ||= {}).merge!(data)
        end
      end
    end
  end
end
