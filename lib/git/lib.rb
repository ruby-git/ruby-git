module Git
  
  class GitExecuteError < StandardError 
  end
  
  class GitNoOutput < StandardError 
  end
  
  class Lib
      
    @base = nil
    
    def initialize(base)
      @base = base
    end
    
    def log_commits(opts = {})
      arr_opts = ['--pretty=oneline']
      arr_opts << "-#{opts[:count]}" if opts[:count]
      arr_opts << "--since=\"#{opts[:since]}\"" if opts[:since].is_a? String
      arr_opts << "#{opts[:between][0]}..#{opts[:between][1].to_s}" if (opts[:between] && opts[:between].size == 2)
      arr_opts << opts[:object] if opts[:object].is_a? String
      arr_opts << '-- ' + opts[:path_limiter] if opts[:path_limiter].is_a? String
      
      command_lines('log', arr_opts).map { |l| l.split.first }
    end
    
    def revparse(string)
      command('rev-parse', string)
    end
    
    def object_type(sha)
      command('cat-file', ['-t', sha])
    end
    
    def object_size(sha)
      command('cat-file', ['-s', sha]).to_i
    end
    
    def object_contents(sha)
      command('cat-file', ['-p', sha])
    end

    def branches_all
      command_lines('branch', '-a').map do |b| 
        current = false
        current = true if b[0, 2] == '* '
        Git::Branch.new(@base, b.gsub('* ', '').strip, current)
      end
    end
    
    def config_remote(name)
      hsh = {}
      command_lines('config', ['--get-regexp', "remote.#{name}"]).each do |line|
        (key, value) = line.split
        hsh[key.gsub("remote.#{name}.", '')] = value
      end
      hsh
    end
    
    # returns hash
    # [tree-ish] = [[line_no, match], [line_no, match2]]
    # [tree-ish] = [[line_no, match], [line_no, match2]]
    def grep(string, opts = {})
      opts[:object] = 'HEAD' if !opts[:object]

      grep_opts = ['-n']
      grep_opts << '-i' if opts[:ignore_case]
      grep_opts << '-v' if opts[:invert_match]
      grep_opts << "-e '#{string}'"
      grep_opts << opts[:object] if opts[:object].is_a? String
      grep_opts << ('-- ' + opts[:path_limiter]) if opts[:path_limiter].is_a? String
      hsh = {}
      command_lines('grep', grep_opts).each do |line|
        if m = /(.*)\:(\d+)\:(.*)/.match(line)        
          hsh[m[1]] ||= []
          hsh[m[1]] << [m[2].to_i, m[3]] 
        end
      end
      hsh
    end
    
    private
    
    def command_lines(cmd, opts)
      command(cmd, opts).split("\n")
    end
    
    def command(cmd, opts)
      ENV['GIT_DIR'] = @base.repo.path
      ENV['GIT_INDEX_FILE'] = @base.index.path   
      ENV['GIT_WORK_DIR'] = @base.dir.path   
      Dir.chdir(@base.dir.path) do  
        opts = opts.to_a.join(' ')
        #puts "git #{cmd} #{opts}"
        out = `git #{cmd} #{opts} 2>&1`.chomp
        #puts out
        if $?.exitstatus > 1
          raise Git::GitExecuteError.new(out)
        end
        out
      end
    end
    
  end
end