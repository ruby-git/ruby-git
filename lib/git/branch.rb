# frozen_string_literal: true

require_relative 'branch_info'

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
  class Branch
    attr_accessor :full, :remote, :name

    # Initialize a new Branch object
    #
    # @api private
    #
    # @note Use {Git::Base#branch} or {Git::Base#branches} instead of constructing directly
    #
    # @param base [Git::Base] the git repository
    # @param branch_info_or_name [Git::BranchInfo, String] branch info object or name string
    #   Passing a BranchInfo is preferred; String support is for backward compatibility.
    #
    def initialize(base, branch_info_or_name)
      @base = base
      @gcommit = nil
      @stashes = nil

      initialize_from_argument(branch_info_or_name)
    end

    def gcommit
      @gcommit ||= @base.gcommit(@full)
      @gcommit
    end

    def stashes
      @stashes ||= Git::Stashes.new(@base)
    end

    def checkout
      check_if_create
      @base.checkout(@full)
    end

    def archive(file, opts = {})
      @base.lib.archive(@full, file, opts)
    end

    # g.branch('new_branch').in_branch do
    #   # create new file
    #   # do other stuff
    #   return true # auto commits and switches back
    # end
    def in_branch(message = 'in branch work')
      old_current = @base.lib.branch_current
      checkout
      if yield
        @base.commit_all(message)
      else
        @base.reset(nil, hard: true)
      end
      @base.checkout(old_current)
    end

    def create
      check_if_create
    end

    def delete
      @base.lib.branch_delete(@name)
    end

    def current # rubocop:disable Naming/PredicateMethod
      @base.lib.branch_current == @name
    end

    def contains?(commit)
      !@base.lib.branch_contains(commit, name).empty?
    end

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

    def update_ref(commit)
      if @remote
        @base.lib.update_ref("refs/remotes/#{@remote.name}/#{@name}", commit)
      else
        @base.lib.update_ref("refs/heads/#{@name}", commit)
      end
    end

    def to_a
      [@full]
    end

    def to_s
      @full
    end

    BRANCH_NAME_REGEXP = %r{
      ^
        # Optional 'refs/remotes/' at the beggining to specify a remote tracking branch
        # with a <remote_name>. <remote_name> is nil if not present.
        (?:
          (?:(?:refs/)?remotes/)(?<remote_name>[^/]+)/
        )?
        (?<branch_name>.*)
      $
    }x

    private

    # @api private
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
    def initialize_from_branch_info(branch_info)
      @full = branch_info.refname
      @name = branch_info.short_name
      @remote = branch_info.remote_name ? Git::Remote.new(@base, branch_info.remote_name) : nil
    end

    # Initialize from a string name (legacy path, deprecated)
    #
    # @param name [String] the branch name
    #
    def initialize_from_name(name)
      @full = name
      @remote, @name = parse_name(name)
    end

    # Given a full branch name return an Array containing the remote and branch names.
    #
    # Removes 'remotes' from the beggining of the name (if present).
    # Takes the second part (splittign by '/') as the remote name.
    # Takes the rest as the repo name (can also hold one or more '/').
    #
    # Example:
    #   # local branches
    #   parse_name('master') #=> [nil, 'master']
    #   parse_name('origin/master') #=> [nil, 'origin/master']
    #   parse_name('origin/master/v2') #=> [nil, 'origin/master']
    #
    #   # remote branches
    #   parse_name('remotes/origin/master') #=> ['origin', 'master']
    #   parse_name('remotes/origin/master/v2') #=> ['origin', 'master/v2']
    #   parse_name('refs/remotes/origin/master') #=> ['origin', 'master']
    #   parse_name('refs/remotes/origin/master/v2') #=> ['origin', 'master/v2']
    #
    # param [String] name branch full name.
    # return [<Git::Remote,NilClass,String>] an Array containing the remote and branch names.
    def parse_name(name)
      # Expect this will always match
      match = name.match(BRANCH_NAME_REGEXP)
      remote = match[:remote_name] ? Git::Remote.new(@base, match[:remote_name]) : nil
      branch_name = match[:branch_name]
      [remote, branch_name]
    end

    def check_if_create
      @base.lib.branch_new(@name)
    rescue StandardError
      nil
    end
  end
end
