# frozen_string_literal: true

require_relative 'branch_info'

module Git
  # Represents a Git branch
  #
  # Branch objects provide access to branch metadata and operations like checkout,
  # delete, and merge. They should be obtained via {Git::Repository#branch} or
  # {Git::Repository#branches}, not constructed directly.
  #
  # @example Getting a branch
  #   git = Git.open('.')
  #   branch = git.branch('main')
  #   branch.checkout
  #
  # @example Listing branches
  #   git.branches.each { |b| puts b.name }
  #
  # @deprecated Use {Git::Repository::Branching#branch_list} and the
  #   name-based branch operations on {Git::Repository} instead
  #
  #   {Git::Repository::Branching#branch_list} returns immutable
  #   {Git::BranchInfo} value objects. Operations that lived on this class are
  #   called on the repository with the branch name instead (for example
  #   {Git::Repository::Branching#checkout} and
  #   {Git::Repository::Branching#branch_delete}). Every operation on a
  #   `Git::Branch` emits a deprecation warning; the `full`, `name`, `remote`,
  #   `to_s`, and `to_a` readers do not.
  #
  # @api public
  #
  class Branch
    # The full refname of this branch
    #
    # For local branches this is the short name (e.g. `'main'`). For
    # remote-tracking branches obtained via {Git::Repository#branches} this includes
    # the `remotes/` prefix (e.g. `'remotes/origin/main'`). Branches constructed
    # by {Git::Remote#branch} use the `<remote>/<branch>` form (e.g.
    # `'origin/main'`) which does **not** populate {#remote}.
    #
    # @example Local and remote-tracking branch full refnames
    #   git.branch('main').full                  #=> 'main'
    #   git.branch('remotes/origin/main').full   #=> 'remotes/origin/main'
    #
    # @return [String] the full refname
    #
    attr_accessor :full

    # The remote for this branch, or `nil` for local or bare-name remote-tracking branches
    #
    # Set to a {Git::Remote} object only when this branch was initialized with a
    # `remotes/<remote>/` or `refs/remotes/<remote>/` prefix. `nil` for local
    # branches and for remote-tracking branches in `<remote>/<branch>` form
    # (such as those returned by {Git::Remote#branch}).
    #
    # @example Local and remote-tracking branches
    #   git.branch('main').remote                  #=> nil
    #   git.branch('remotes/origin/main').remote   #=> #<Git::Remote 'origin'>
    #   git.remote('origin').branch('main').remote #=> nil  # uses 'origin/main' form
    #
    # @return [Git::Remote, nil] the remote object, or `nil`
    #
    attr_accessor :remote

    # The short branch name without the remote prefix
    #
    # For both local and remote-tracking branches this is the bare branch
    # name (e.g. `'main'` rather than `'remotes/origin/main'`).
    #
    # @example Local and remote-tracking branch short names
    #   git.branch('main').name                  #=> 'main'
    #   git.branch('remotes/origin/main').name   #=> 'main'
    #
    # @return [String] the short branch name
    #
    attr_accessor :name

    # Initialize a new Branch object
    #
    # @param base [Git::Repository] the git repository
    #
    # @param branch_info_or_name [Git::BranchInfo, String] branch info object or name string
    #
    #   Passing a BranchInfo is preferred; String support is for backward compatibility.
    #
    # @note Use {Git::Repository#branch} or {Git::Repository#branches} instead of constructing directly
    #
    # @api private
    #
    def initialize(base, branch_info_or_name)
      @base = base
      @gcommit = nil
      @stashes = nil

      initialize_from_argument(branch_info_or_name)
    end

    # Returns the commit at the tip of this branch
    #
    # The result is memoized after the first call.
    #
    # @example Get the tip commit
    #   git.branch('main').gcommit #=> #<Git::Object ...>
    #
    # @return [Git::Object] the commit at the tip of this branch
    #
    # @deprecated Use {Git::Repository::ObjectOperations#gcommit} with the branch name instead
    #
    #   Pass the branch name for a local branch, or `"remotes/#{remote}/#{name}"`
    #   (the value of {#full}) for a remote-tracking branch; the shorter
    #   `"#{remote}/#{name}"` can resolve a local branch of that name.
    #
    # @see Git::Repository::ObjectOperations#gcommit
    #
    def gcommit
      Git::Deprecation.warn(
        'Git::Branch#gcommit is deprecated and will be removed in v6.0.0. ' \
        'Use Git::Repository#gcommit(name) or, for a remote-tracking branch, ' \
        'Git::Repository#gcommit("remotes/remote/name") instead.'
      )
      @gcommit ||= branch_repository.gcommit(@full)
      @gcommit
    end

    # Returns the stash list for this repository
    #
    # This method ignores the branch receiver and returns every stash in the
    # repository, so `git.branch('feature').stashes` and
    # `git.branch('main').stashes` return the same entries. It is deprecated and
    # will be removed in v6.0.0.
    #
    # The result is memoized after the first call.
    #
    # @example Iterate over stash entries
    #   git.branch('main').stashes.each { |s| puts s }
    #
    # @return [Git::Stashes] the stash list
    #
    # @deprecated Use {Git::Repository#stashes_all} instead
    #
    # @see Git::Repository#stashes_all
    #
    def stashes
      Git::Deprecation.warn(
        'Git::Branch#stashes is deprecated and will be removed in v6.0.0. ' \
        'It ignores the branch and returns all repository stashes. ' \
        'Use Git::Repository#stashes_all instead.'
      )
      @stashes ||= Git::Stashes.new(branch_repository)
    end

    # Checks out this branch, attempting to create it first if it does not already exist
    #
    # Branch creation is attempted via {#check_if_create}; any error from that
    # step is silently ignored and the checkout proceeds regardless.
    #
    # **Note:** for remote-tracking branches (where {#remote} is not `nil`),
    # `check_if_create` will attempt to create a *local* branch named {#name}
    # as a side-effect before checking out {#full} (which typically results in
    # a detached HEAD). This is a known limitation; see
    # [ruby-git#1280](https://github.com/ruby-git/ruby-git/issues/1280).
    #
    # @example Check out a branch
    #   git = Git.open('.')
    #   git.branch('main').checkout
    #
    # @return [String] git's stdout from the checkout
    #
    # @raise [Git::FailedError] if git exits with a non-zero exit status
    #
    # @deprecated Use {Git::Repository::Branching#checkout} with the branch name instead
    #
    #   {Git::Repository::Branching#checkout} does not create a missing local
    #   branch, apart from the guess git makes on its own: with no `:no_guess`
    #   option, git creates a tracking branch when exactly one remote has a
    #   branch of that name. To reproduce the create-or-checkout behavior of
    #   this method, call {Git::Repository::Branching#branch_new} when
    #   {Git::Repository::Branching#local_branch?} is false, then
    #   {Git::Repository::Branching#checkout}. Pass `"remotes/#{remote}/#{name}"`
    #   (the value of {#full}) for a remote-tracking branch; the shorter
    #   `"#{remote}/#{name}"` can resolve a local branch of that name.
    #
    # @see Git::Repository::Branching#checkout
    #
    # @see Git::Repository::Branching#branch_new
    #
    def checkout
      Git::Deprecation.warn(
        'Git::Branch#checkout is deprecated and will be removed in v6.0.0. ' \
        'Use Git::Repository#checkout(name) or, for a remote-tracking branch, ' \
        'Git::Repository#checkout("remotes/remote/name") instead. Git::Repository#checkout does not ' \
        'create a missing local branch (beyond the guess git makes from a unique remote-tracking ' \
        'branch); call Git::Repository#branch_new first unless Git::Repository#local_branch? is true.'
      )
      check_if_create
      branch_repository.checkout(@full)
    end

    # Archives this branch and writes the result to a file
    #
    # @example Archive to a tar file
    #   git.branch('main').archive('/tmp/main.tar', format: 'tar')
    #
    # @example Archive to a zip file
    #   git.branch('main').archive('/tmp/main.zip', format: 'zip')
    #
    # @example Archive a remote branch to a tgz file
    #   git.remote('origin').branch('main').archive('/tmp/main.tgz', format: 'tgz')
    #
    # @param file [String] path to the destination archive file
    #
    # @param opts [Hash] archive options (see {Git::Repository#archive})
    #
    # @option opts [String] :format ('zip') archive format for this wrapper:
    #   `'tar'`, `'zip'`, or `'tgz'`
    #
    # @option opts [String] :prefix (nil) prefix prepended to every filename
    #   in the archive
    #
    # @option opts [String] :path (nil) path within the tree to include in the
    #   archive
    #
    # @option opts [String] :remote (nil) retrieve the archive from a remote
    #   repository
    #
    # @option opts [Boolean, nil] :add_gzip (nil) apply gzip compression after
    #   writing the archive; set automatically when `format: 'tgz'` is given
    #
    # @return [String] the path to the written archive file
    #
    # @raise [ArgumentError] when archive options or destination path are invalid
    #
    # @raise [Git::FailedError] if `git archive` fails
    #
    # @deprecated Use {Git::Repository::ObjectOperations#archive} with the branch name instead
    #
    #   Pass the branch name for a local branch, or `"remotes/#{remote}/#{name}"`
    #   (the value of {#full}) for a remote-tracking branch; the shorter
    #   `"#{remote}/#{name}"` can resolve a local branch of that name.
    #
    # @see Git::Repository::ObjectOperations#archive
    #
    def archive(file, opts = {})
      Git::Deprecation.warn(
        'Git::Branch#archive is deprecated and will be removed in v6.0.0. ' \
        'Use Git::Repository#archive(name, file, opts) or, for a remote-tracking branch, ' \
        'Git::Repository#archive("remotes/remote/name", file, opts) instead.'
      )
      branch_repository.archive(@full, file, opts)
    end

    # Checks out this branch for the duration of a block, then restores the original branch
    #
    # If the block returns a truthy value, all pending changes are committed with the
    # given message before switching back to the original branch. If the block returns
    # a falsy value, a hard reset is performed before switching back.
    #
    # **Note:** the restore checkout is not wrapped in `ensure`. If the block,
    # the commit, or the reset raises an exception, the repository will be left
    # checked out on this branch rather than restored to the original.
    #
    # @example Commit a new file on a feature branch
    #   git.branch('feature').in_branch('Add README') do
    #     File.write('README.md', '# Hello')
    #     git.add('README.md')
    #     true  # commit and return to original branch
    #   end
    #
    # @param message [String] commit message used when the block returns truthy
    #
    # @return [String] git's stdout from the final checkout back to the original branch
    #
    # @raise [Git::FailedError] if any of the underlying git operations (checkout, commit, reset) fail
    #
    # @yield Executes the block with this branch checked out
    #
    # @yieldreturn [Object] return a truthy value to commit all changes, a falsy value to hard-reset
    #
    # @deprecated Use {Git::Repository::Branching#in_branch} with the branch name instead
    #
    #   {Git::Repository::Branching#in_branch} does not create the branch and
    #   restores a detached HEAD to its original commit.
    #   It takes an existing local branch, so a remote-tracking `Git::Branch` has
    #   no direct replacement: this method checked out the remote-tracking ref,
    #   detaching HEAD. Create a local branch from that ref with
    #   {Git::Repository::Branching#branch_new} first.
    #
    # @see Git::Repository::Branching#in_branch
    #
    def in_branch(message = 'in branch work')
      Git::Deprecation.warn(
        'Git::Branch#in_branch is deprecated and will be removed in v6.0.0. ' \
        'Use Git::Repository#in_branch(name, message) instead. It takes an existing local ' \
        'branch; for a remote-tracking branch, create a local branch from it first.'
      )
      old_current = branch_repository.current_branch
      # checkout is deprecated too; silence it so one in_branch call emits one warning
      Git::Deprecation.silence { checkout }
      yield ? branch_repository.commit_all(message) : branch_repository.reset(nil, hard: true)
      branch_repository.checkout(old_current)
    end

    # Creates this branch if it does not already exist
    #
    # Silently ignores any error raised during branch creation (including the case
    # where the branch already exists).
    #
    # @example Create a new branch
    #   git.branch('feature').create
    #
    # @return [nil]
    #
    # @deprecated Use {Git::Repository::Branching#branch_new} instead
    #
    #   {Git::Repository::Branching#branch_new} raises {Git::FailedError} when
    #   the branch already exists rather than ignoring the error.
    #
    # @see Git::Repository::Branching#branch_new
    #
    def create
      Git::Deprecation.warn(
        'Git::Branch#create is deprecated and will be removed in v6.0.0. ' \
        'Use Git::Repository#branch_new instead.'
      )
      check_if_create
    end

    # Deletes this branch
    #
    # Remote-tracking branches (one where {#remote} is not `nil`) delete the
    # local remote-tracking ref; they do not push a deletion to the remote.
    #
    # @example Delete a local branch
    #   git.branch('old-feature').delete
    #
    # @return [String] git's deletion output
    #
    # @raise [Git::Error] if the branch cannot be deleted
    #
    # @deprecated Use {Git::Repository::Branching#branch_delete} instead
    #
    #   Pass the branch name for a local branch, or `"#{remote}/#{name}"` with
    #   `remotes: true` for a remote-tracking branch.
    #
    # @see Git::Repository::Branching#branch_delete
    #
    def delete
      Git::Deprecation.warn(
        'Git::Branch#delete is deprecated and will be removed in v6.0.0. ' \
        'Use Git::Repository#branch_delete(name) or, for a remote-tracking branch, ' \
        'Git::Repository#branch_delete("remote/name", remotes: true) instead.'
      )
      if @remote
        branch_repository.branch_delete("#{@remote.name}/#{@name}", remotes: true)
      else
        branch_repository.branch_delete(@name)
      end
    end

    # Returns true if this is the currently checked-out branch
    #
    # **Note:** this compares the current branch's short name against {#name}.
    # For a remote-tracking branch (where {#remote} is not `nil`), {#name} is
    # still the bare short name (e.g. `'main'`), so this will return `true`
    # whenever the *local* branch with that name is checked out — not the
    # remote-tracking ref itself.
    #
    # @example Check whether currently on main
    #   git.branch('main').current #=> true
    #
    # @return [Boolean] whether this branch is currently checked out
    #
    # @raise [Git::FailedError] if git exits with a non-zero exit status
    #
    # @deprecated Compare {Git::Repository::Branching#current_branch} with the
    #   branch name instead
    #
    # @see Git::Repository::Branching#current_branch
    #
    def current # rubocop:disable Naming/PredicateMethod
      Git::Deprecation.warn(
        'Git::Branch#current is deprecated and will be removed in v6.0.0. ' \
        'Use Git::Repository#current_branch == name instead.'
      )
      branch_repository.current_branch == @name
    end

    # Returns true if this branch contains the given commit
    #
    # **Note:** this queries local branches by short name. For a remote-tracking
    # branch (where {#remote} is not `nil`), it checks the *local* branch with
    # the same {#name} rather than the remote-tracking ref, which may give an
    # inaccurate result.
    #
    # @example Check if a commit is reachable from this branch
    #   git.branch('main').contains?('abc1234') #=> true
    #
    # @param commit [String] the commit SHA or ref to check
    #
    # @return [Boolean] whether this branch contains the given commit
    #
    # @raise [Git::FailedError] if git exits with a non-zero exit status
    #
    # @deprecated Use {Git::Repository::Branching#branch_contains} with the
    #   commit and branch name instead
    #
    #   {Git::Repository::Branching#branch_contains} returns the matching
    #   branch names as a String; test it with `empty?`.
    #
    # @see Git::Repository::Branching#branch_contains
    #
    def contains?(commit)
      Git::Deprecation.warn(
        'Git::Branch#contains? is deprecated and will be removed in v6.0.0. ' \
        'Use !Git::Repository#branch_contains(commit, name).empty? instead.'
      )
      !branch_repository.branch_contains(commit, name).empty?
    end

    # Merges a branch into this branch, or merges this branch into the current branch
    #
    # @overload merge(branch, message = nil)
    #
    #   Temporarily checks out this branch, merges the given branch into it,
    #   then restores the original branch.
    #
    #   **Note:** if `self` is a remote-tracking branch (where {#remote} is not
    #   `nil`), this delegates to {#checkout} which has the detached-HEAD
    #   side-effect described there. The remote-tracking ref will not be updated.
    #
    #   @example Merge a feature branch into main
    #     git.branch('main').merge('feature')
    #
    #   @param branch [String] the name of the branch to merge into this one
    #
    #   @param message [String, nil] commit message for the merge commit
    #
    #   @return [String] git's stdout from the final checkout back to the original branch
    #
    # @overload merge()
    #
    #   Merges this branch into the currently checked-out branch.
    #
    #   @example Merge main into the current branch
    #     git.branch('main').merge
    #
    #   @return [String] git's stdout from the merge command
    #
    # @raise [Git::FailedError] if git exits with a non-zero exit status
    #
    # @deprecated Use {Git::Repository::Merging#merge_into} in place of
    #   `merge(branch)` and {Git::Repository::Merging#merge} with the branch
    #   name in place of `merge()`
    #
    #   {Git::Repository::Merging#merge_into} returns the merge's stdout, does
    #   not hard-reset after the merge, and restores a detached HEAD to its
    #   original commit.
    #   It takes an existing local branch, so a remote-tracking `Git::Branch` has
    #   no direct replacement: `merge(branch)` checked out the remote-tracking ref,
    #   detaching HEAD. Create a local branch from that ref with
    #   {Git::Repository::Branching#branch_new} first.
    #
    # @see Git::Repository::Merging#merge_into
    #
    # @see Git::Repository::Merging#merge
    #
    def merge(branch = nil, message = nil)
      if branch
        merge_into_this_branch(branch, message)
      else
        merge_into_current_branch
      end
    end

    # Updates the git ref for this branch to point to the given commit
    #
    # The target ref depends on whether {#remote} is set:
    # - When {#remote} is not `nil` (i.e. the branch was initialized with a
    #   `remotes/<remote>/` or `refs/remotes/<remote>/` prefix), updates
    #   `refs/remotes/<remote>/<name>`.
    # - Otherwise updates `refs/heads/<name>`. Note that branches in the
    #   `<remote>/<branch>` form (e.g. those returned by {Git::Remote#branch})
    #   have `remote == nil` and therefore update `refs/heads/<remote>/<name>`,
    #   **not** `refs/remotes/...`.
    #
    # @example Advance a local branch to a new commit
    #   git.branch('feature').update_ref('abc1234def5678')
    #
    # @param commit [String] the commit SHA to point this branch at
    #
    # @return [Git::CommandLine::Result] the result of calling `git update-ref`
    #
    # @raise [Git::FailedError] if git exits with a non-zero exit status
    #
    # @deprecated Use {Git::Repository::Branching#update_ref} instead
    #
    #   Pass the branch name for a local branch, or
    #   `"remotes/#{remote}/#{name}"` for a remote-tracking branch.
    #
    # @see Git::Repository::Branching#update_ref
    #
    def update_ref(commit)
      Git::Deprecation.warn(
        'Git::Branch#update_ref is deprecated and will be removed in v6.0.0. ' \
        'Use Git::Repository#update_ref(name, commit) or, for a remote-tracking branch, ' \
        'Git::Repository#update_ref("remotes/remote/name", commit) instead.'
      )
      if @remote
        branch_repository.update_ref("remotes/#{@remote.name}/#{@name}", commit)
      else
        branch_repository.update_ref(@name, commit)
      end
    end

    # Returns this branch as a single-element array containing its full refname
    #
    # @example Get branch as array
    #   git.branch('main').to_a #=> ['main']
    #
    # @return [Array<String>] a single-element array containing the full refname
    #
    def to_a
      [@full]
    end

    # Returns the full refname of this branch as a string
    #
    # @example Get branch as string
    #   git.branch('main').to_s #=> 'main'
    #
    # @return [String] the full refname
    #
    def to_s
      @full
    end

    # Regular expression for parsing branch refnames
    #
    # Matches full and short refnames, capturing an optional remote name and the
    # branch name. Used internally to identify remote-tracking branches.
    #
    # @note This legacy string-constructor path does not resolve remote names
    #   containing `/`. Use {Git::Repository#branch_list} to build branch objects
    #   from remote-aware {Git::BranchInfo} values.
    #
    # @api private
    #
    BRANCH_NAME_REGEXP = %r{
      ^
        # Optional 'remotes/' or 'refs/remotes/' at the beginning to specify a remote tracking branch
        # with a <remote_name>. <remote_name> is nil if not present.
        (?:
          (?:(?:refs/)?remotes/)(?<remote_name>[^/]+)/
        )?
        (?<branch_name>.*)
      $
    }x

    private

    # Dispatches initialization to the appropriate strategy
    #
    # @param branch_info_or_name [Git::BranchInfo, String] branch info or name string
    #
    # @return [nil]
    #
    # @api private
    #
    def initialize_from_argument(branch_info_or_name)
      if branch_info_or_name.is_a?(Git::BranchInfo)
        initialize_from_branch_info(branch_info_or_name)
      else
        initialize_from_name(branch_info_or_name)
      end
    end

    # Initialize from a BranchInfo object (preferred path)
    #
    # @param branch_info [Git::BranchInfo] the branch info
    #
    # @return [nil]
    #
    def initialize_from_branch_info(branch_info)
      @name = branch_info.short_name
      remote_name = branch_info.remote_name
      # Git::Remote is deprecated too; silence it so one Git::Branch call emits one warning
      @remote = remote_name ? Git::Deprecation.silence { Git::Remote.new(@base, remote_name) } : nil
      @full = @remote ? "remotes/#{@remote.name}/#{@name}" : @name
    end

    # Initialize from a string name (legacy path for backward compatibility)
    #
    # @param name [String] the branch name
    #
    # @return [nil]
    #
    def initialize_from_name(name)
      @full = name
      @remote, @name = parse_name(name)
    end

    # Parses a full branch name into remote and short branch name components
    #
    # Strips an optional `remotes/` or `refs/remotes/` prefix. Only inputs that
    # begin with one of those prefixes yield a remote object; all other inputs
    # (including `'origin/master'`) are treated as local branch names with a
    # `nil` remote.
    #
    # @example Local branches
    #   parse_name('master')            #=> [nil, 'master']
    #   parse_name('origin/master')     #=> [nil, 'origin/master']
    #
    # @example Remote-tracking branches
    #   parse_name('remotes/origin/master')      #=> [#<Git::Remote 'origin'>, 'master']
    #   parse_name('refs/remotes/origin/master') #=> [#<Git::Remote 'origin'>, 'master']
    #
    # @param name [String] the full branch name to parse
    #
    # @return [Array(Git::Remote, String)] a two-element array; the first element is
    #   a {Git::Remote} for remote-tracking branches or `nil` for local branches,
    #   and the second element is the short branch name
    #
    def parse_name(name)
      # Expect this will always match
      match = name.match(BRANCH_NAME_REGEXP)
      remote_name = match[:remote_name]
      # Git::Remote is deprecated too; silence it so one Git::Branch call emits one warning
      remote = remote_name ? Git::Deprecation.silence { Git::Remote.new(@base, remote_name) } : nil
      branch_name = match[:branch_name]
      [remote, branch_name]
    end

    # Merges the given branch into this branch, then restores the original branch
    #
    # @param branch [String] the name of the branch to merge into this one
    #
    # @param message [String, nil] commit message for the merge commit
    #
    # @return [String] git's stdout from the final checkout back to the original branch
    #
    # @api private
    #
    def merge_into_this_branch(branch, message)
      Git::Deprecation.warn(
        'Git::Branch#merge(branch) is deprecated and will be removed in v6.0.0. ' \
        'Use Git::Repository#merge_into(name, branch, message) instead. It takes an existing ' \
        'local branch; for a remote-tracking branch, create a local branch from it first.'
      )
      # in_branch is deprecated too; silence it so one merge call emits one warning.
      # The falsy block value makes in_branch hard-reset instead of committing.
      Git::Deprecation.silence do
        in_branch { branch_repository.merge(branch, message) && false }
      end
    end

    # Merges this branch into the currently checked-out branch
    #
    # @return [String] git's stdout from the merge command
    #
    # @api private
    #
    def merge_into_current_branch
      Git::Deprecation.warn(
        'Git::Branch#merge with no arguments is deprecated and will be removed in v6.0.0. ' \
        'Use Git::Repository#merge(name) instead.'
      )
      branch_repository.merge(@name)
    end

    # Creates the branch if it does not already exist, ignoring errors
    #
    # @return [nil]
    #
    def check_if_create
      branch_repository.branch_new(@name)
    rescue StandardError
      nil
    end

    # @return [Git::Repository]
    #
    # @api private
    #
    def branch_repository
      @base
    end
  end
end
