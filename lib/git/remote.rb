# frozen_string_literal: true

require 'git/branch'
require 'git/branch_info'

module Git
  # A remote in a Git repository
  #
  # Remote objects provide access to remote metadata and operations like fetch,
  # merge, and remove. This class and `Git::Repository#remote`, which returns
  # it, are both deprecated: read remote configuration through
  # {Git::Repository::RemoteOperations#remote_list} and call the
  # repository-level operations with the remote name instead.
  #
  # @example Reading a remote and fetching from it without Git::Remote
  #   git = Git.open('.')
  #   origin = git.remote_list.find { |r| r.name == 'origin' }  #=> Git::RemoteInfo
  #   origin.url.first
  #   git.fetch(origin.name)
  #
  # @deprecated Use {Git::Repository::RemoteOperations#remote_list} and the
  #   repository-level remote operations instead
  #
  #   {Git::Repository::RemoteOperations#remote_list} returns immutable
  #   {Git::RemoteInfo} value objects. Operations that lived on this class are
  #   called on the repository with the remote name instead (for example
  #   {Git::Repository::RemoteOperations#fetch} and
  #   {Git::Repository::RemoteOperations#remote_remove}). Constructing a
  #   `Git::Remote` emits a deprecation warning.
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
    # @note Do not construct directly. `Git::Repository#remote` is deprecated as
    #   well; use {Git::Repository::RemoteOperations#remote_list} and the
    #   repository-level remote operations instead.
    #
    # @api private
    #
    def initialize(base, name)
      Git::Deprecation.warn(
        'Git::Remote is deprecated and will be removed in v6.0.0. ' \
        'Use Git::Repository#remote_list and the repository-level remote operations instead.'
      )
      @base = base
      # config_remote is deprecated too; silence it so one Git::Remote.new emits one warning
      config = Git::Deprecation.silence { remote_repository.config_remote(name) }
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
    # @deprecated Use
    #   `Git::Repository#branch_list("#{name}/#{branch || current_branch}").first`
    #   instead
    #
    #   With no argument this method falls back to the current branch, so the
    #   replacement has to supply `Git::Repository#current_branch` itself. The
    #   replacement returns a {Git::BranchInfo} value object rather than a
    #   {Git::Branch}, and returns `nil` when the remote-tracking branch does
    #   not exist.
    #
    def branch(branch = nil)
      branch ||= remote_repository.current_branch
      Git::Branch.new(@base, "#{@name}/#{branch}")
    end

    # Removes this remote from the repository
    #
    # @example Remove the upstream remote
    #   git.remote('upstream').remove
    #
    # @return [Git::CommandLine::Result] the result of `git remote remove`
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
  end
end
