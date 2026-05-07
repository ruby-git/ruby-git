# frozen_string_literal: true

require 'git/path'

module Git
  # Represents a Git branch
  #
  # Branch objects provide access to branch metadata and operations like checkout,
  # delete, and merge. They should be obtained via {Git::Base#branch} or
  # {Git::Base#branches}, not constructed directly.
  #
  # @example Getting a branch
  #   git = Git.open('.')
  #   branch = git.branch('main')
  #   branch.checkout
  #
  # @example Listing branches
  #   git.branches.each { |b| puts b.name }
  #
  # @api public
  #
  class Branch
    # The full refname of this branch
    #
    # For local branches this is the short name (e.g. `'main'`). For
    # remote-tracking branches obtained via {Git::Base#branches} this includes
    # the `remotes/` prefix (e.g. `'remotes/origin/main'`). Branches constructed
    # by {Git::Remote#branch} use the `<remote>/<branch>` form (e.g.
    # `'origin/main'`) which does **not** populate {#remote}.
    #
    # @example
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
    # @example
    #   git.branch('main').remote                  #=> nil
    #   git.branch('remotes/origin/main').remote   #=> #<Git::Remote 'origin'>
    #   git.remote('origin').branch('main').remote #=> nil  # uses 'origin/main' form
    #
    # @return [Git::Remote, nil] the remote object, or `nil`
    #
    attr_accessor :remote

    # The short branch name without the remote prefix
    #
    # For branches initialized with a `remotes/` or `refs/remotes/` prefix, the
    # prefix is stripped and this returns the bare branch name (e.g. `'main'`
    # rather than `'remotes/origin/main'`). For branches in the
    # `<remote>/<branch>` form (such as those created by {Git::Remote#branch}),
    # no stripping occurs and `name` returns the full form (e.g. `'origin/main'`).
    #
    # @example
    #   git.branch('main').name                       #=> 'main'
    #   git.branch('remotes/origin/main').name        #=> 'main'
    #   git.remote('origin').branch('main').name      #=> 'origin/main'
    #
    # @return [String] the branch name
    #
    attr_accessor :name

    # Initialize a new Branch object
    #
    # @api private
    #
    # @note Use {Git::Base#branch} or {Git::Base#branches} instead of constructing directly
    #
    # @param base [Git::Base] the git repository
    #
    # @param name [String] the full or short branch name
    #
    def initialize(base, name)
      @full = name
      @base = base
      @gcommit = nil
      @stashes = nil
      @remote, @name = parse_name(name)
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
    def gcommit
      @gcommit ||= @base.gcommit(@full)
      @gcommit
    end

    # Returns the stash list for this repository
    #
    # The result is memoized after the first call.
    #
    # @example Iterate over stash entries
    #   git.branch('main').stashes.each { |s| puts s }
    #
    # @return [Git::Stashes] the stash list
    #
    def stashes
      @stashes ||= Git::Stashes.new(@base)
    end

    # Checks out this branch, attempting to create it first if it does not already exist
    #
    # Branch creation is attempted via {#check_if_create}; any error from that
    # step is silently ignored and the checkout proceeds regardless.
    #
    # **Note:** for remote-tracking branches (where {#remote} is not `nil`),
    # {#full} is a ref such as `'remotes/origin/main'`. Checking out a
    # remote-tracking ref places the repository in a **detached HEAD** state.
    #
    # @example Check out a branch
    #   git = Git.open('.')
    #   git.branch('main').checkout
    #
    # @return [String] git's stdout from the checkout
    #
    # @raise [Git::FailedError] if git exits with a non-zero exit status
    #
    def checkout
      check_if_create
      @base.checkout(@full)
    end

    # Archives this branch and writes the result to a file
    #
    # @example Archive to a tar file
    #   git.branch('main').archive('/tmp/main.tar')
    #
    # @example Archive to a zip file
    #   git.branch('main').archive('/tmp/main.zip', format: 'zip')
    #
    # @param file [String] path to the destination archive file
    #
    # @param opts [Hash] archive options (see {Git::Base#archive})
    #
    # @return [String] the path to the written archive file
    #
    # @raise [Git::FailedError] if `git archive` fails
    #
    def archive(file, opts = {})
      @base.lib.archive(@full, file, opts)
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
    # @yield Executes the block with this branch checked out
    #
    # @yieldreturn [Object] return a truthy value to commit all changes, a falsy value to hard-reset
    #
    # @return [String] git's stdout from the final checkout back to the original branch
    #
    # @raise [Git::FailedError] if any of the underlying git operations (checkout, commit, reset) fail
    #
    def in_branch(message = 'in branch work')
      old_current = @base.lib.branch_current
      checkout
      if yield
        @base.commit_all(message)
      else
        @base.reset_hard
      end
      @base.checkout(old_current)
    end

    # Creates this branch if it does not already exist
    #
    # Silently ignores any error raised during branch creation (including the case
    # where the branch already exists).
    #
    # @example Create a new branch
    #   git.branch('feature').create
    #
    # @return [String, nil] git's stdout from branch creation (typically empty),
    #   or `nil` if an error was rescued
    #
    def create
      check_if_create
    end

    # Deletes this branch
    #
    # **Note:** this method only works correctly for local branches. Calling it on
    # a remote-tracking branch (one where {#remote} is not `nil`) will attempt to
    # delete a *local* branch with the same short name rather than the
    # remote-tracking ref, which is almost certainly not what you want.
    # See [ruby-git#1280](https://github.com/ruby-git/ruby-git/issues/1280) for
    # the planned fix.
    #
    # @example Delete a local branch
    #   git.branch('old-feature').delete
    #
    # @return [String] git's deletion output
    #
    # @raise [Git::FailedError] if the branch cannot be deleted
    #
    def delete
      @base.lib.branch_delete(@name)
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
    # @raise [Git::FailedError] if git exits with a non-zero exit status
    #
    #
    def current # rubocop:disable Naming/PredicateMethod
      @base.lib.branch_current == @name
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
    # @raise [Git::FailedError] if git exits with a non-zero exit status
    #
    #
    def contains?(commit)
      !@base.lib.branch_contains(commit, name).empty?
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
    # @raise [Git::FailedError] if git exits with a non-zero exit status during
    #   the merge, checkout, commit, or reset operations
    #
    def merge(branch = nil, message = nil)
      if branch
        in_branch do
          @base.merge(branch, message)
          false
        end
        # merge a branch into this one
      else
        # merge this branch into the current one
        @base.merge(@name)
      end
    end

    # Updates the git ref for this branch to point to the given commit
    #
    # The target ref depends on whether {#remote} is set:
    # - When {#remote} is not `nil` (i.e. the branch was initialised with a
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
    # @return [String] the stdout output from `git update-ref`
    #
    # @raise [Git::FailedError] if git exits with a non-zero exit status
    #
    def update_ref(commit)
      if @remote
        @base.lib.update_ref("refs/remotes/#{@remote.name}/#{@name}", commit)
      else
        @base.lib.update_ref("refs/heads/#{@name}", commit)
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

    # Parses a full branch name into remote and short branch name components
    #
    # Strips an optional `remotes/` or `refs/remotes/` prefix. Only inputs that begin
    # with one of those prefixes yield a remote object; all other inputs (including
    # `'origin/master'`) are treated as local branch names with a `nil` remote.
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
    # @return [Array(Git::Remote, String)] a two-element array with the remote object
    #   (or `nil`) and the short branch name
    #
    def parse_name(name)
      # Expect this will always match
      match = name.match(BRANCH_NAME_REGEXP)
      remote = match[:remote_name] ? Git::Remote.new(@base, match[:remote_name]) : nil
      branch_name = match[:branch_name]
      [remote, branch_name]
    end

    # Creates the branch if it does not already exist, ignoring errors
    #
    # @return [String, nil] stdout from branch creation, or `nil` if an error was rescued
    #
    def check_if_create
      @base.lib.branch_new(@name)
    rescue StandardError
      nil
    end
  end
end
