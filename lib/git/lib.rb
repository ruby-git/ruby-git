module Git
  
  class GitExecuteError < StandardError 
  end
  
  class Lib
      
    @base = nil
    
    def initialize(base)
      @base = base
    end
    
    def log_commits(opts)
      arr_opts = ['--pretty=oneline']
      arr_opts << "-#{opts[:count]}" if opts[:count]
      arr_opts << "--since=\"#{opts[:since]}\"" if opts[:since].is_a? String
      arr_opts << "#{opts[:between][0]}..#{opts[:between][1].to_s}" if (opts[:between] && opts[:between].size == 2)
      arr_opts << opts[:file] if opts[:file].is_a? String
      
      command('log', arr_opts).split("\n").map { |l| Git::Object::Commit.new(@base, l.split.first) }
    end
    
    def revparse(string)
      command('rev-parse', string)
    end
    
    def object_type(sha)
      command('cat-file', ['-t', sha])
    end
    
    def object_size(sha)
      command('cat-file', ['-s', sha])
    end
    
    def object_contents(sha)
      command('cat-file', ['-p', sha])
    end
    
    private
    
    def command(cmd, opts)
      ENV['GIT_DIR'] = @base.repo.path
      ENV['GIT_INDEX_FILE'] = @base.index.path   
      ENV['GIT_WORK_DIR'] = @base.dir.path   
      Dir.chdir(@base.dir.path) do  
        opts = opts.to_a.join(' ')
        #puts "git #{cmd} #{opts}"
        out = `git #{cmd} #{opts} 2>&1`.chomp
        if $?.exitstatus != 0
          raise Git::GitExecuteError.new(out)
        end
        out
      end
    end
    
  end
end