# frozen_string_literal: true

module Git
  # Collection of all Git branches in a repository
  #
  # Wraps both local and remote-tracking branches and provides filtering,
  # enumeration, and name-based lookup.
  #
  # @example Enumerate all branches
  #   branches = repo.branches
  #   branches.each { |b| puts b.name }
  #
  # @deprecated Use {Git::Repository::Branching#branch_list} instead
  #
  #   {Git::Repository::Branching#branch_list} returns `Array<Git::BranchInfo>`
  #   (immutable value objects). Filter it with `select(&:remote?)` or
  #   `reject(&:remote?)` in place of {#remote} and {#local}, and look a
  #   branch up by name with `branch_list(name).first` in place of {#[]}.
  #   Constructing a `Git::Branches` emits a deprecation warning.
  #
  # @api public
  #
  class Branches
    include Enumerable

    # Creates a new Branches collection populated from the given repository
    #
    # @param base [Git::Repository] the repository to enumerate
    #   branches from
    #
    # @return [void]
    #
    # @raise [Git::FailedError] if git exits with a non-zero exit status
    #
    # @deprecated Use {Git::Repository::Branching#branch_list} instead
    #
    # @see Git::Repository::Branching#branch_list
    #
    def initialize(base)
      Git::Deprecation.warn(
        'Git::Branches is deprecated and will be removed in v6.0.0. ' \
        'Use Git::Repository#branch_list instead.'
      )
      @branches = {}
      @lookup = {}

      @base = base

      load_branches
    end

    # Returns all local (non-remote-tracking) branches
    #
    # @example List local branch names
    #   repo.branches.local.map(&:name)
    #
    # @return [Array<Git::Branch>] the local branches
    #
    def local
      reject(&:remote)
    end

    # Returns all remote-tracking branches
    #
    # @example List remote branch names
    #   repo.branches.remote.map(&:name)
    #
    # @return [Array<Git::Branch>] the remote-tracking branches
    #
    def remote
      self.select(&:remote)
    end

    # Returns the number of branches in the collection
    #
    # @example Count all branches
    #   repo.branches.size  # => 3
    #
    # @return [Integer] the total number of branches
    #
    def size
      @branches.size
    end

    # Iterates over every branch in the collection
    #
    # @overload each
    #
    #   @example Get an enumerator over all branches
    #     enum = repo.branches.each
    #
    #   @return [Enumerator<Git::Branch>] an enumerator over all branches
    #
    # @overload each(&block)
    #
    #   @example Print every branch name
    #     repo.branches.each { |b| puts b.name }
    #
    #   @return [Array<Git::Branch>] the full list of branches
    #
    #   @yield [branch] passes each branch to the block
    #
    #   @yieldparam branch [Git::Branch] a branch in the repository
    #
    #   @yieldreturn [void]
    #
    def each(&)
      @branches.values.each(&)
    end

    # Returns the branch with the given name
    #
    # Supports short names (`'main'`), remote-qualified names
    # (`'working/master'`), and full refspec names
    # (`'remotes/working/master'`).
    #
    # @example Look up a branch by short name
    #   repo.branches['main']
    #
    # @example Look up a remote-tracking branch
    #   repo.branches['working/master']
    #
    # @param branch_name [#to_s] the name of the branch to retrieve
    #
    # @return [Git::Branch, nil] the matching branch, or `nil` if not found
    #
    def [](branch_name)
      @lookup[branch_name.to_s]
    end

    # Returns a string listing all branches, prefixed with `*` for the current branch
    #
    # @example Display all branches
    #   puts repo.branches.to_s
    #
    # @return [String] a formatted branch listing
    #
    def to_s
      out = +''
      @branches.each_value do |b|
        # Git::Branch#current is deprecated too; silence it so one to_s call emits one warning
        current = Git::Deprecation.silence { b.current }
        out << (current ? '* ' : '  ') << b.to_s << "\n"
      end
      out
    end

    private

    # Builds a Git::Branch for every branch in the repository and indexes it
    #
    # @return [void]
    #
    # @api private
    #
    def load_branches
      branch_repository.branch_list.each do |branch_info|
        branch = Git::Branch.new(@base, branch_info)

        @branches[branch_info.refname] = branch
        index_branch_lookup(branch, refname: branch_info.refname)
      end
    end

    # @return [Git::Repository] the repository used to enumerate branches
    #
    # @api private
    #
    def branch_repository
      @base
    end

    # Indexes all supported lookup keys for a branch without mutating
    # the canonical `@branches` collection used by enumeration
    #
    # @param branch [Git::Branch] the branch to index
    #
    # @param refname [String] the full refname key to use for primary lookup
    #
    # @return [void]
    #
    # @api private
    #
    def index_branch_lookup(branch, refname:)
      @lookup[refname] ||= branch
      @lookup[branch.full] ||= branch

      return unless branch.full.start_with?('remotes/')

      # Mirror git compatibility: allow omitting a leading "remotes/".
      @lookup[branch.full.delete_prefix('remotes/')] ||= branch
    end
  end
end
