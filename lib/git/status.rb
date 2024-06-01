module Git
  # The status class gets the status of a git repository
  #
  # This identifies which files have been modified, added, or deleted from the
  # worktree. Untracked files are also identified.
  #
  # The Status object is an Enumerable that contains StatusFile objects.
  #
  # @api public
  #
  class Status
    include Enumerable

    def initialize(base)
      @base = base
      construct_status
    end

    #
    # Returns an Enumerable containing files that have changed from the
    # git base directory
    #
    # @return [Enumerable]
    def changed
      @_changed ||= @files.select { |_k, f| f.type == 'M' }
    end

    #
    # Determines whether the given file has been changed.
    # File path starts at git base directory
    #
    # @param file [String] The name of the file.
    # @example Check if lib/git.rb has changed.
    #     changed?('lib/git.rb')
    # @return [Boolean]
    def changed?(file)
      case_aware_include?(:changed, :lc_changed, file)
    end

    # Returns an Enumerable containing files that have been added.
    # File path starts at git base directory
    #
    # @return [Enumerable]
    def added
      @_added ||= @files.select { |_k, f| f.type == 'A' }
    end

    # Determines whether the given file has been added to the repository
    #
    # File path starts at git base directory
    #
    # @param file [String] The name of the file.
    # @example Check if lib/git.rb is added.
    #     added?('lib/git.rb')
    # @return [Boolean]
    def added?(file)
      case_aware_include?(:added, :lc_added, file)
    end

    #
    # Returns an Enumerable containing files that have been deleted.
    # File path starts at git base directory
    #
    # @return [Enumerable]
    def deleted
      @_deleted ||= @files.select { |_k, f| f.type == 'D' }
    end

    #
    # Determines whether the given file has been deleted from the repository
    # File path starts at git base directory
    #
    # @param file [String] The name of the file.
    # @example Check if lib/git.rb is deleted.
    #     deleted?('lib/git.rb')
    # @return [Boolean]
    def deleted?(file)
      case_aware_include?(:deleted, :lc_deleted, file)
    end

    #
    # Returns an Enumerable containing files that are not tracked in git.
    # File path starts at git base directory
    #
    # @return [Enumerable]
    def untracked
      @_untracked ||= @files.select { |_k, f| f.untracked }
    end

    #
    # Determines whether the given file has is tracked by git.
    # File path starts at git base directory
    #
    # @param file [String] The name of the file.
    # @example Check if lib/git.rb is an untracked file.
    #     untracked?('lib/git.rb')
    # @return [Boolean]
    def untracked?(file)
      case_aware_include?(:untracked, :lc_untracked, file)
    end

    def pretty
      out = ''
      each do |file|
        out << pretty_file(file)
      end
      out << "\n"
      out
    end

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

    # enumerable method

    def [](file)
      @files[file]
    end

    def each(&block)
      @files.values.each(&block)
    end

    # subclass that does heavy lifting
    class StatusFile
      # @!attribute [r] path
      #   The path of the file relative to the project root directory
      #   @return [String]
      attr_accessor :path

      # @!attribute [r] type
      #   The type of change
      #
      #   * 'M': modified
      #   * 'A': added
      #   * 'D': deleted
      #   * nil: ???
      #
      #   @return [String]
      attr_accessor :type

      # @!attribute [r] mode_index
      #   The mode of the file in the index
      #   @return [String]
      #   @example 100644
      #
      attr_accessor :mode_index

      # @!attribute [r] mode_repo
      #   The mode of the file in the repo
      #   @return [String]
      #   @example 100644
      #
      attr_accessor :mode_repo

      # @!attribute [r] sha_index
      #   The sha of the file in the index
      #   @return [String]
      #   @example 123456
      #
      attr_accessor :sha_index

      # @!attribute [r] sha_repo
      #   The sha of the file in the repo
      #   @return [String]
      #   @example 123456
      attr_accessor :sha_repo

      # @!attribute [r] untracked
      #   Whether the file is untracked
      #   @return [Boolean]
      attr_accessor :untracked

      # @!attribute [r] stage
      #   The stage of the file
      #
      #   * '0': the unmerged state
      #   * '1': the common ancestor (or original) version
      #   * '2': "our version" from the current branch head
      #   * '3': "their version" from the other branch head
      #   @return [String]
      attr_accessor :stage

      def initialize(base, hash)
        @base = base
        @path = hash[:path]
        @type = hash[:type]
        @stage = hash[:stage]
        @mode_index = hash[:mode_index]
        @mode_repo = hash[:mode_repo]
        @sha_index = hash[:sha_index]
        @sha_repo = hash[:sha_repo]
        @untracked = hash[:untracked]
      end

      def blob(type = :index)
        if type == :repo
          @base.object(@sha_repo)
        else
          begin
            @base.object(@sha_index)
          rescue
            @base.object(@sha_repo)
          end
        end
      end
    end

    private

    def construct_status
      # Lists all files in the index and the worktree
      # git ls-files --stage
      # { file => { path: file, mode_index: '100644', sha_index: 'dd4fc23', stage: '0' } }
      @files = @base.lib.ls_files

      # Lists files in the worktree that are not in the index
      # Add untracked files to @files
      fetch_untracked

      # Lists files that are different between the index vs. the worktree
      fetch_modified

      # Lists files that are different between the repo HEAD vs. the worktree
      fetch_added

      @files.each do |k, file_hash|
        @files[k] = StatusFile.new(@base, file_hash)
      end
    end

    def fetch_untracked
      # git ls-files --others --exclude-standard, chdir: @git_work_dir)
      # { file => { path: file, untracked: true } }
      @base.lib.untracked_files.each do |file|
        @files[file] = { path: file, untracked: true }
      end
    end

    def fetch_modified
      # Files changed between the index vs. the worktree
      # git diff-files
      # { file => { path: file, type: 'M', mode_index: '100644', mode_repo: '100644', sha_index: '0000000', :sha_repo: '52c6c4e' } }
      @base.lib.diff_files.each do |path, data|
        @files[path] ? @files[path].merge!(data) : @files[path] = data
      end
    end

    def fetch_added
      unless @base.lib.empty?
      # Files changed between the repo HEAD vs. the worktree
      # git diff-index HEAD
      # { file => { path: file, type: 'M', mode_index: '100644', mode_repo: '100644', sha_index: '0000000', :sha_repo: '52c6c4e' } }
      @base.lib.diff_index('HEAD').each do |path, data|
          @files[path] ? @files[path].merge!(data) : @files[path] = data
        end
      end
    end

    # It's worth noting that (like git itself) this gem will not behave well if
    # ignoreCase is set inconsistently with the file-system itself. For details:
    # https://git-scm.com/docs/git-config#Documentation/git-config.txt-coreignoreCase
    def ignore_case?
      return @_ignore_case if defined?(@_ignore_case)
      @_ignore_case = @base.config('core.ignoreCase') == 'true'
    rescue Git::FailedError
      @_ignore_case = false
    end

    def downcase_keys(hash)
      hash.map { |k, v| [k.downcase, v] }.to_h
    end

    def lc_changed
      @_lc_changed ||= changed.transform_keys(&:downcase)
    end

    def lc_added
      @_lc_added ||= added.transform_keys(&:downcase)
    end

    def lc_deleted
      @_lc_deleted ||= deleted.transform_keys(&:downcase)
    end

    def lc_untracked
      @_lc_untracked ||= untracked.transform_keys(&:downcase)
    end

    def case_aware_include?(cased_hash, downcased_hash, file)
      if ignore_case?
        send(downcased_hash).include?(file.downcase)
      else
        send(cased_hash).include?(file)
      end
    end
  end
end
