# frozen_string_literal: true

require 'git/branch'
require 'git/branch_info'

module Git
  # A remote in a Git repository
  #
  # Remote objects provide access to remote metadata and operations like fetch,
  # merge, and remove. They should be obtained via `Git::Repository#remote`,
  # not constructed directly.
  #
  # @example Getting a remote
  #   git = Git.open('.')
  #   remote = git.remote('origin')
  #   remote.fetch
  #
  # @api public
  #
  class Remote
    # The name of this remote (e.g. `'origin'`)
    #
    # @return [String] the remote name
    #
    attr_accessor :name

    # The URL of this remote
    #
    # @return [String, nil] the remote URL
    #
    attr_accessor :url

    # The fetch refspec for this remote
    #
    # @return [String, nil] the fetch options string
    #
    attr_accessor :fetch_opts

    # Initialize a new Remote object
    #
    # @param base [Git::Repository] the git repository
    #
    # @param name [String] the remote name (e.g. `'origin'`)
    #
    # @note Use `Git::Repository#remote` instead of constructing directly
    #
    # @api private
    #
    def initialize(base, name)
      @base = base
      config = remote_repository.config_remote(name)
      @name = name
      @url = config['url']
      @fetch_opts = config['fetch']
    end

    # Fetches from this remote
    #
    # @example Fetch from origin
    #   git.remote('origin').fetch
    #
    # @param opts [Hash] options for the fetch command
    #
    # @option opts [Boolean, nil] :tags (nil) fetch all tags from the remote
    #   (`--tags`)
    #
    # @option opts [Boolean, nil] :prune (nil) remove remote-tracking references
    #   that no longer exist on the remote (`--prune`)
    #
    # @option opts [Boolean, nil] :prune_tags (nil) remove local tags that no
    #   longer exist on the remote (`--prune-tags`)
    #
    # @option opts [Boolean, nil] :force (nil) override the fast-forward check
    #   when using explicit refspecs (`--force`)
    #
    # @option opts [Boolean, nil] :update_head_ok (nil) allow `git fetch` to
    #   update the branch pointed to by `HEAD` (`--update-head-ok`)
    #
    # @option opts [Boolean, nil] :unshallow (nil) convert a shallow clone into a
    #   full repository (`--unshallow`)
    #
    # @option opts [String, Integer, nil] :depth (nil) limit history to N commits
    #   from each branch tip (`--depth=N`)
    #
    # @option opts [String, Array<String>, nil] :ref (nil) one or more refspecs to
    #   fetch as positional arguments after the remote name
    #
    # @return [String] git's stdout from the fetch
    #
    # @raise [Git::FailedError] if git exits with a non-zero exit status
    #
    def fetch(opts = {})
      remote_repository.fetch(@name, opts)
    end

    # Merges this remote into the given (or current) local branch
    #
    # @example Merge origin/main into the current branch
    #   git.remote('origin').merge('main')
    #
    # @param branch [String] the local branch to merge into (defaults to current branch)
    #
    # @return [String] git's stdout from the merge
    #
    # @raise [Git::FailedError] if git exits with a non-zero exit status
    #
    def merge(branch = nil)
      branch ||= remote_repository.current_branch
      remote_tracking_branch = "#{@name}/#{branch}"
      remote_repository.merge(remote_tracking_branch)
    end

    # Returns a {Git::Branch} object for the given branch on this remote
    #
    # @example Get the remote-tracking branch object
    #   git.remote('origin').branch('main')  #=> #<Git::Branch 'origin/main'>
    #
    # @param branch [String] the branch name on this remote (defaults to current branch)
    #
    # @return [Git::Branch] a branch object representing `<remote>/<branch>`
    #
    def branch(branch = nil)
      branch ||= remote_repository.current_branch
      remote_tracking_branch = "#{@name}/#{branch}"
      branch_info = build_branch_info(remote_tracking_branch)
      Git::Branch.new(@base, branch_info)
    end

    # Removes this remote from the repository
    #
    # @example Remove the upstream remote
    #   git.remote('upstream').remove
    #
    # @return [Git::CommandLineResult] the result of `git remote remove`
    #
    # @raise [Git::FailedError] if git exits with a non-zero exit status
    #
    def remove
      remote_repository.remote_remove(@name)
    end

    # Returns the name of this remote as a string
    #
    # @example Get the remote name as a string
    #   git.remote('origin').to_s  #=> 'origin'
    #
    # @return [String] the remote name
    #
    def to_s
      @name
    end

    private

    # @return [Git::Repository]
    #
    # @api private
    #
    def remote_repository
      @base
    end

    # Builds branch metadata for a remote-tracking branch
    #
    # @param refname [String] remote-tracking branch name (for example,
    #   `'origin/main'`)
    #
    # @return [Git::BranchInfo] minimal branch metadata for constructing
    #   {Git::Branch}
    #
    def build_branch_info(refname)
      Git::BranchInfo.new(
        refname: refname,
        target_oid: nil,
        current: false,
        worktree: false,
        symref: nil,
        upstream: nil
      )
    end
  end
end
