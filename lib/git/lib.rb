module Git
  
  class GitExecuteError < StandardError 
  end
  
  class Lib
      
    @git_dir = nil
    @git_index_file = nil
    @git_work_dir = nil
        
    def initialize(base)
      if base.is_a?(Git::Base)
        @git_dir = base.repo.path
        @git_index_file = base.index.path   
        @git_work_dir = base.dir.path
      elsif base.is_a?(Hash)
        @git_dir = base[:repository]
        @git_index_file = base[:index] 
        @git_work_dir = base[:working_directory]
      end
    end
    
    def init
      command('init')
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
      arr = []
      command_lines('branch', '-a').each do |b| 
        current = false
        current = true if b[0, 2] == '* '
        arr << [b.gsub('* ', '').strip, current]
      end
      arr
    end

    def config_get(name)
      command('config', ['--get', name])
    end
    
    def config_list
      hsh = {}
      command_lines('config', ['--list']).each do |line|
        (key, value) = line.split('=')
        hsh[key] = value
      end
      hsh
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
      grep_opts << opts[:object] if opts[:object].is_a?(String)
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
    
    def diff_full(obj1 = 'HEAD', obj2 = nil, opts = {})
      diff_opts = ['-p']
      diff_opts << obj1
      diff_opts << obj2 if obj2.is_a?(String)
      diff_opts << ('-- ' + opts[:path_limiter]) if opts[:path_limiter].is_a? String
      
      command('diff', diff_opts)
    end
    
    def diff_stats(obj1 = 'HEAD', obj2 = nil, opts = {})
      diff_opts = ['--numstat']
      diff_opts << obj1
      diff_opts << obj2 if obj2.is_a?(String)
      diff_opts << ('-- ' + opts[:path_limiter]) if opts[:path_limiter].is_a? String
      
      hsh = {:total => {:insertions => 0, :deletions => 0, :lines => 0, :files => 0}, :files => {}}
      
      command_lines('diff', diff_opts).each do |file|
        (insertions, deletions, filename) = file.split("\t")
        hsh[:total][:insertions] += insertions.to_i
        hsh[:total][:deletions] += deletions.to_i
        hsh[:total][:lines] = (hsh[:total][:deletions] + hsh[:total][:insertions])
        hsh[:total][:files] += 1
        hsh[:files][filename] = {:insertions => insertions.to_i, :deletions => deletions.to_i}
      end
            
      hsh
    end
    
    private
    
    def command_lines(cmd, opts)
      command(cmd, opts).split("\n")
    end
    
    def command(cmd, opts = {})
      ENV['GIT_DIR'] = @git_dir
      ENV['GIT_INDEX_FILE'] = @git_index_file if @git_index_file
      ENV['GIT_WORK_DIR'] = @git_work_dir if @git_work_dir
      Dir.chdir(@git_work_dir || @git_dir) do  
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