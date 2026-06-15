# frozen_string_literal: true

require 'git/base'

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
    def initialize(base)
      @branches = {}
      @lookup = {}

      @base = base

      branch_repository.branches_all.each do |branch_info|
        branch = Git::Branch.new(base, branch_info)

        @branches[branch_info.refname] = branch
        index_branch_lookup(branch, refname: branch_info.refname)
      end
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
        out << (b.current ? '* ' : '  ') << b.to_s << "\n"
      end
      out
    end

    private

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
