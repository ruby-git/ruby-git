# frozen_string_literal: true

module Git
  # Regular expression for parsing branch refnames
  #
  # Captures:
  #   - remote_name: the remote name (e.g., 'origin') for remote branches, nil for local
  #   - branch_name: the branch name without the remote prefix
  #
  # @example Parse branch refnames
  #   'main' => { remote_name: nil, branch_name: 'main' }
  #   'refs/heads/main' => { remote_name: nil, branch_name: 'main' }
  #   'remotes/origin/main' => { remote_name: 'origin', branch_name: 'main' }
  #   'refs/remotes/origin/main' => { remote_name: 'origin', branch_name: 'main' }
  #   'feature/foo' => { remote_name: nil, branch_name: 'feature/foo' }
  #   'remotes/origin/feature/bar' => { remote_name: 'origin', branch_name: 'feature/bar' }
  #
  # @note This regex handles both raw full refs (e.g., `refs/heads/main`) as stored in
  #   {Git::BranchInfo#refname} and normalized short-form refs (e.g., `main`,
  #   `remotes/origin/main`) used elsewhere.
  #
  # @note This regex is a fallback for branch refnames parsed without configured
  #   remote context. Remote names containing '/' can only be resolved reliably
  #   when the parser is given the configured remote names. See:
  #   https://github.com/ruby-git/ruby-git/issues/919
  #
  # @api private
  BRANCH_REFNAME_REGEXP = %r{
    \A                                            # start of string
    (?:refs/heads/)?                              # optional refs/heads/ prefix (stripped)
    (?:(?:refs/)?remotes/(?<remote_name>[^/]+)/)? # optional refs?/remotes/<remote_name>/
    (?<branch_name>.+)                            # branch name (everything else)
    \z                                            # end of string
  }x

  # Sentinel for distinguishing omitted BranchInfo remote_name from explicit nil
  REMOTE_NAME_NOT_GIVEN = Object.new.freeze
  private_constant :REMOTE_NAME_NOT_GIVEN

  # Value object representing branch metadata from git branch output
  #
  # This is a lightweight, immutable data structure returned by branch listing
  # commands. It contains only the data parsed from git output without any
  # repository context or operations.
  #
  # @example Local branch with upstream tracking
  #   info = Git::BranchInfo.new(
  #     refname: 'refs/heads/main',
  #     target_oid: 'abc123def456789012345678901234567890abcd',
  #     current: true,
  #     worktree_path: nil,
  #     symref: nil,
  #     upstream: 'refs/remotes/origin/main'
  #   )
  #   info.current?     #=> true
  #   info.remote?      #=> false
  #   info.short_name   #=> 'main'
  #   info.upstream     #=> 'refs/remotes/origin/main'
  #
  # @example Remote-tracking branch
  #   info = Git::BranchInfo.new(
  #     refname: 'refs/remotes/origin/main',
  #     target_oid: 'abc123def456789012345678901234567890abcd',
  #     current: false,
  #     worktree_path: nil,
  #     symref: nil,
  #     upstream: nil
  #   )
  #   info.remote?      #=> true
  #   info.remote_name  #=> 'origin'
  #   info.short_name   #=> 'main'
  #
  # @see Git::Branch for the full-featured branch object with operations
  #
  # @see Git::Commands::Branch::List for the command that produces these
  #
  # @api public
  #
  # @!attribute [r] refname
  #
  #   The full reference name of the branch
  #
  #   Must be the full refname as returned by git (e.g., 'refs/heads/main',
  #   'refs/remotes/origin/main') because the short name alone is not guaranteed to
  #   be unique (e.g., 'main' could exist as both a local and remote branch).
  #
  #   @return [String] the branch refname (e.g., 'refs/heads/main',
  #     'refs/remotes/origin/main')
  #
  # @!attribute [r] remote_name
  #
  #   @return [String, nil] the resolved or fallback-derived remote name, or nil
  #     for local branches
  #
  # @!attribute [r] target_oid
  #
  #   The commit object ID (SHA) that this branch points to (aka HEAD)
  #
  #   @return [String, nil] the full 40-character object ID, or nil if branch is
  #   unborn (no commits yet)
  #
  # @!attribute [r] current
  #
  #   Whether this branch is currently checked out in the current worktree
  #
  #   @return [Boolean] true if this is the current branch
  #
  #   @note A branch can be current ({#current?} true) or in another worktree
  #     ({#other_worktree?} true), but never both. A branch not checked out
  #     anywhere has both false.
  #
  # @!attribute [r] worktree_path
  #
  #   The absolute path of the *other* linked worktree this branch is checked
  #   out in, or nil.
  #
  #   This is nil in two distinct cases:
  #   - The branch is the current branch in this worktree (use {#current?} to
  #     distinguish that case)
  #   - The branch is not checked out in any worktree
  #
  #   This path is suppressed for the current branch even though git reports it
  #   via `%(worktreepath)`, because the current worktree's path is already
  #   known from the repository object and storing it here would make
  #   {#other_worktree?} incorrect.
  #
  #   @return [String, nil] the absolute path of the linked worktree root
  #     directory (e.g., `'/home/user/projects/my-repo-hotfix'`), or nil if
  #     the branch is not checked out in a different linked worktree
  #
  # @!attribute [r] symref
  #
  #   The target reference if this is a symbolic reference
  #
  #   @return [String, nil] the target ref (e.g., 'refs/heads/main'), or nil if not a symref
  #
  # @!attribute [r] upstream
  #
  #   The configured upstream/tracking branch refname as reported by git
  #
  #   @return [String, nil] the raw upstream refname from `%(upstream)`
  #     (e.g., `'refs/remotes/origin/main'`), or nil if no upstream is configured
  #
  #   @note Remote-tracking branches (e.g., `'refs/remotes/origin/main'`) have upstream: nil
  #
  #   @note This is the raw refname snapshot from when the branch list was read.
  #     It does not reflect live git state after the snapshot was taken.
  #
  BranchInfo = Data.define(:refname, :remote_name, :target_oid, :current, :worktree_path, :symref, :upstream) do
    # @param refname [String] the full branch refname
    #
    # @param remote_name [String, nil] resolved remote name, nil for local branches,
    #   or omitted to derive from `refname`
    #
    # @param target_oid [String, nil] the commit object ID, or nil for unborn branches
    #
    # @param current [Boolean] whether this branch is currently checked out
    #
    # @param worktree_path [String, nil] path to another linked worktree, or nil
    #
    # @param symref [String, nil] symbolic reference target, or nil
    #
    # @param upstream [String, nil] upstream refname, or nil
    #
    def initialize(refname:, target_oid:, current:, worktree_path:, symref:, upstream:, # rubocop:disable Metrics/ParameterLists
                   remote_name: REMOTE_NAME_NOT_GIVEN)
      remote_name = self.class.fallback_remote_name(refname) if remote_name.equal?(REMOTE_NAME_NOT_GIVEN)
      self.class.validate_remote_name!(refname, remote_name)

      super
    end

    # @param refname [String] the branch refname to validate
    #
    # @param remote_name [String, nil] the remote name to validate
    #
    # @return [void]
    #
    # @raise [ArgumentError] if the remote name contradicts the refname type
    def self.validate_remote_name!(refname, remote_name)
      if remote_tracking_refname?(refname)
        unless remote_name.is_a?(String) && !remote_name.empty?
          raise ArgumentError, 'remote_name must be a non-empty String for remote-tracking refname'
        end

        remote_ref_prefix = %r{\A(?:refs/)?remotes/#{Regexp.escape(remote_name)}/}
        raise ArgumentError, 'remote_name must match remote-tracking refname' unless refname.match?(remote_ref_prefix)
      elsif !remote_name.nil?
        raise ArgumentError, 'remote_name must be nil for local branch refname'
      end
    end

    # @param refname [String] the branch refname to parse
    #
    # @return [String, nil] the regex-derived remote name, or nil for local branches
    def self.fallback_remote_name(refname)
      refname.match(Git::BRANCH_REFNAME_REGEXP)[:remote_name]
    end

    # @param refname [String] the branch refname to inspect
    #
    # @return [Boolean] true if the refname is a remote-tracking refname
    def self.remote_tracking_refname?(refname)
      refname.match?(%r{\A(?:refs/)?remotes/[^/]+/.+})
    end

    # @return [Boolean] always false for BranchInfo (see DetachedHeadInfo for detached state)
    def detached? = false

    # @return [Boolean] true if this is an unborn branch (no commits yet)
    def unborn? = target_oid.nil?

    # @return [String] the short branch name without any remote or heads prefix
    #   (e.g., 'main' or 'feature/foo')
    def short_name
      return refname.delete_prefix('refs/heads/') if remote_name.nil?

      remote_ref_prefix = %r{\A(?:refs/)?remotes/#{Regexp.escape(remote_name)}/}
      refname.sub(remote_ref_prefix, '')
    end

    # @return [Boolean] true if this is the currently checked out branch
    def current? = current

    # @return [Boolean] true if this branch is checked out in another linked worktree
    def other_worktree? = !worktree_path.nil?

    # @return [Boolean] true if this is a symbolic reference
    def symref? = !symref.nil?

    # @return [Boolean] true if this is a remote-tracking branch
    def remote? = !remote_name.nil?

    # @return [String] string representation (the full refname)
    def to_s = refname
  end
end
