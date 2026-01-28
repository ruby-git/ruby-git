# frozen_string_literal: true

module Git
  # A remote in a Git repository
  class Remote
    attr_accessor :name, :url, :fetch_opts

    def initialize(base, name)
      @base = base
      config = @base.lib.config_remote(name)
      @name = name
      @url = config['url']
      @fetch_opts = config['fetch']
    end

    def fetch(opts = {})
      @base.fetch(@name, opts)
    end

    # merge this remote locally
    def merge(branch = @base.current_branch)
      remote_tracking_branch = "#{@name}/#{branch}"
      @base.merge(remote_tracking_branch)
    end

    def branch(branch = @base.current_branch)
      remote_tracking_branch = "#{@name}/#{branch}"
      branch_info = Git::BranchInfo.new(
        refname: remote_tracking_branch,
        target_oid: nil,
        current: false,
        worktree: false,
        symref: nil,
        upstream: nil
      )
      Git::Branch.new(@base, branch_info)
    end

    def remove
      @base.lib.remote_remove(@name)
    end

    def to_s
      @name
    end
  end
end
