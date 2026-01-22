# frozen_string_literal: true

module Git
  # Regular expression for parsing branch refnames
  #
  # Captures:
  #   - remote_name: the remote name (e.g., 'origin') for remote branches, nil for local
  #   - branch_name: the branch name without the remote prefix
  #
  # @note This regex is similar to Git::Branch::BRANCH_NAME_REGEXP but uses \A/\z anchors
  #   instead of ^/$ for stricter matching. As part of the architectural redesign,
  #   Git::Branch will eventually be refactored to use BranchInfo internally, at which
  #   point this will become the single source of truth for branch name parsing.
  #
  # @note This regex assumes remote names do not contain '/'. If a remote name
  #   contains '/', parsing will be incorrect. For example, 'remotes/team/upstream/main'
  #   would parse as remote_name='team' instead of 'team/upstream'. This is an inherent
  #   ambiguity in git refnames that can only be resolved with knowledge of configured
  #   remotes. See: https://github.com/ruby-git/ruby-git/issues/919
  #
  # @example
  #   'main' => { remote_name: nil, branch_name: 'main' }
  #   'remotes/origin/main' => { remote_name: 'origin', branch_name: 'main' }
  #   'feature/foo' => { remote_name: nil, branch_name: 'feature/foo' }
  #   'remotes/origin/feature/bar' => { remote_name: 'origin', branch_name: 'feature/bar' }
  #
  # @api private
  BRANCH_REFNAME_REGEXP = %r{
    \A                              # start of string
    (?:(?:refs/)?remotes/(?<remote_name>[^/]+)/)? # optional 'refs?/remotes/<remote_name>/'
    (?<branch_name>.+)                   # branch name (everything else)
    \z                              # end of string
  }x

  # Value object representing branch metadata from git branch output
  #
  # This is a lightweight, immutable data structure returned by branch listing
  # commands. It contains only the data parsed from git output without any
  # repository context or operations.
  #
  # @example Creating from git branch output
  #   info = Git::BranchInfo.new(
  #     refname: 'main',
  #     current: true,
  #     worktree: false,
  #     symref: nil
  #   )
  #   info.current?     #=> true
  #   info.remote?      #=> false
  #   info.short_name   #=> 'main'
  #
  # @example Remote branch
  #   info = Git::BranchInfo.new(
  #     refname: 'remotes/origin/main',
  #     current: false,
  #     worktree: false,
  #     symref: nil
  #   )
  #   info.remote?      #=> true
  #   info.remote_name  #=> 'origin'
  #   info.short_name   #=> 'main'
  #
  # @see Git::Branch for the full-featured branch object with operations
  # @see Git::Commands::Branch::List for the command that produces these
  #
  # @api public
  #
  BranchInfo = Data.define(:refname, :current, :worktree, :symref) do
    # @return [Boolean] true if this is the currently checked out branch
    def current? = current

    # @return [Boolean] true if this branch is checked out in another worktree
    def worktree? = worktree

    # @return [Boolean] true if this is a symbolic reference
    def symref? = !symref.nil?

    # @return [Boolean] true if this is a remote-tracking branch
    def remote? = !remote_name.nil?

    # @return [String, nil] the name of the remote (e.g., 'origin'), or nil for local branches
    def remote_name
      parse_refname[:remote_name]
    end

    # @return [String] the branch name without remote prefix (e.g., 'main' or 'feature/foo')
    def short_name
      parse_refname[:branch_name]
    end

    # @return [String] string representation (the full refname)
    def to_s = refname

    private

    # Parse the refname and return match data
    #
    # The regex is guaranteed to match any non-empty string due to the `.+` pattern,
    # so we don't need nil checking. If refname is empty/nil, this would fail at
    # object creation time since refname is a required attribute.
    #
    # @return [MatchData] the match result
    def parse_refname
      refname.match(Git::BRANCH_REFNAME_REGEXP)
    end
  end
end
