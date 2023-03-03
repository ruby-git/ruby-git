module Git
  class Remote < Path

    attr_accessor :name, :url, :fetch_opts

    def initialize(base, name)
      @base = base
      config = @base.lib.config_remote(name)
      @name = name
      @url = config['url']
      @fetch_opts = config['fetch']
    end

    def fetch(opts={})
      @base.fetch(@name, opts)
    end

    # merge this remote locally
    def merge(branch = @base.current_branch)
      remote_tracking_branch = "#{@name}/#{branch}"
      @base.merge(remote_tracking_branch)
    end

    def branch(branch = @base.current_branch)
      remote_tracking_branch = "#{@name}/#{branch}"
      Git::Branch.new(@base, remote_tracking_branch)
    end

    def remove
      @base.lib.remote_remove(@name)
    end

    def to_s
      @name
    end

  end
end
