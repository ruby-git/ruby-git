module Git
  class Lib
    
    @base = nil
    
    def initialize(base)
      @base = base
    end
    
    def log_shas(count)
      command('log', "-#{count} --pretty=oneline").split("\n").map { |l| Git::Commit.new(l.split.first) }
    end
    
    private
    
    def command(cmd, opts)
      ENV['GIT_DIR'] = @base.repo.path   
      `git #{cmd} #{opts}`
    end
    
  end
end