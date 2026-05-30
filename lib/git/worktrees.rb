# frozen_string_literal: true

require 'git/base'

module Git
  # Collection of all Git worktrees in a repository
  #
  # Wraps every linked and main worktree and provides enumeration and
  # path-based lookup.
  #
  # Accepts either a {Git::Repository} (new form) or a {Git::Base} (legacy
  # form) as the `base` argument. The `is_a?(Git::Base)` guard routes git
  # operations through the facade repository and will be removed when
  # {Git::Base} is deleted in Phase 4.
  #
  # @example Enumerate all worktrees
  #   worktrees = repo.worktrees
  #   worktrees.each { |wt| puts wt.dir }
  #
  # @api public
  #
  class Worktrees
    include Enumerable

    # Creates a new Worktrees collection populated from the given repository
    #
    # @param base [Git::Base, Git::Repository] the repository to enumerate
    #   worktrees from
    #
    # @return [void]
    #
    # @raise [Git::FailedError] if git exits with a non-zero exit status
    #
    def initialize(base)
      @worktrees = {}

      @base = base

      worktree_repository.worktrees_all.each do |w|
        @worktrees[w[0]] = Git::Worktree.new(@base, w[0], w[1])
      end
    end

    # Returns the number of worktrees in the collection
    #
    # @example Count all worktrees
    #   repo.worktrees.size  # => 2
    #
    # @return [Integer] the total number of worktrees
    #
    def size
      @worktrees.size
    end

    # Iterates over every worktree in the collection
    #
    # @overload each
    #
    #   @example Get an enumerator over all worktrees
    #     enum = repo.worktrees.each
    #
    #   @return [Enumerator<Git::Worktree>] an enumerator over all worktrees
    #
    # @overload each(&block)
    #
    #   @example Print every worktree path
    #     repo.worktrees.each { |wt| puts wt.dir }
    #
    #   @return [Array<Git::Worktree>] the full list of worktrees
    #
    #   @yield [worktree] passes each worktree to the block
    #
    #   @yieldparam worktree [Git::Worktree] a worktree in the repository
    #
    #   @yieldreturn [void]
    #
    def each(&)
      @worktrees.values.each(&)
    end

    # Returns the worktree with the given path
    #
    # Supports lookup by the filesystem path of the worktree directory or by
    # the full worktree descriptor (path and optional commitish).
    #
    # @example Look up a worktree by path
    #   repo.worktrees['/path/to/linked-worktree']
    #
    # @param worktree_name [#to_s] the path (or full descriptor) of the
    #   worktree to retrieve
    #
    # @return [Git::Worktree, nil] the matching worktree, or `nil` if not found
    #
    def [](worktree_name)
      @worktrees.values.each_with_object(@worktrees) do |worktree, worktrees|
        worktrees[worktree.full] ||= worktree
      end[worktree_name.to_s]
    end

    # Returns a string listing all worktrees, one per line
    #
    # @example Display all worktrees
    #   puts repo.worktrees.to_s
    #
    # @return [String] a newline-separated listing of worktree descriptors
    #
    def to_s
      out = +''
      @worktrees.each_value do |b|
        out << b.to_s << "\n"
      end
      out
    end

    # Removes stale administrative files for worktrees that no longer exist
    #
    # Runs `git worktree prune` to clean up any lingering worktree metadata
    # for linked worktrees whose directories have been deleted.
    #
    # @example Prune stale worktree metadata
    #   repo.worktrees.prune
    #
    # @return [String] stdout from the git command (typically empty)
    #
    # @raise [Git::FailedError] if git exits with a non-zero exit status
    #
    def prune
      worktree_repository.worktree_prune
    end

    private

    # Resolves the {Git::Repository} for this collection of worktrees
    #
    # Accepts either a {Git::Repository} (new form) or a {Git::Base} (legacy).
    # The `is_a?(Git::Base)` guard will be removed when {Git::Base} is deleted
    # in Phase 4.
    #
    # @return [Git::Repository] the repository used to enumerate worktrees
    #
    # @api private
    #
    def worktree_repository
      @base.is_a?(Git::Base) ? @base.facade_repository : @base
    end
  end
end
