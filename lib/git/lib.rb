module Git
  
  class GitExecuteError < StandardError 
  end
  
  class Lib
      
    @git_dir = nil
    @git_index_file = nil
    @git_work_dir = nil
    @path = nil
        
    def initialize(base = nil)
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
    
    # tries to clone the given repo
    #
    # returns {:repository} (if bare)
    #         {:working_directory} otherwise
    #
    # accepts options:
    #  :remote - name of remote (rather than 'origin')
    #  :bare   - no working directory
    # 
    # TODO - make this work with SSH password or auth_key
    #
    def clone(repository, name, opts = {})
      @path = opts[:path] || '.'
      opts[:path] ? clone_dir = File.join(@path, name) : clone_dir = name
      
      arr_opts = []
      arr_opts << "--bare" if opts[:bare]
      arr_opts << "-o #{opts[:remote]}" if opts[:remote]
      arr_opts << repository
      arr_opts << clone_dir
      
      command('clone', arr_opts)
      
      opts[:bare] ? {:repository => clone_dir} : {:working_directory => clone_dir}
    end
    
    
    ## READ COMMANDS ##
    
    
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

    # compares the index and the working directory
    def diff_files
      hsh = {}
      command_lines('diff-files').each do |line|
        (info, file) = line.split("\t")
        (mode_src, mode_dest, sha_src, sha_dest, type) = info.split
        hsh[file] = {:path => file, :mode_file => mode_src.to_s[1, 7], :mode_index => mode_dest, 
                      :sha_file => sha_src, :sha_index => sha_dest, :type => type}
      end
      hsh
    end
    
    # compares the index and the repository
    def diff_index(treeish)
      hsh = {}
      command_lines('diff-index', treeish).each do |line|
        (info, file) = line.split("\t")
        (mode_src, mode_dest, sha_src, sha_dest, type) = info.split
        hsh[file] = {:path => file, :mode_repo => mode_src.to_s[1, 7], :mode_index => mode_dest, 
                      :sha_repo => sha_src, :sha_index => sha_dest, :type => type}
      end
      hsh
    end
            
    def ls_files
      hsh = {}
      command_lines('ls-files', '--stage').each do |line|
        (info, file) = line.split("\t")
        (mode, sha, stage) = info.split
        hsh[file] = {:path => file, :mode_index => mode, :sha_index => sha, :stage => stage}
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
    
    ## WRITE COMMANDS ##
        
    def config_set(name, value)
      command('config', [name, "'#{value}'"])
    end
          
    def add(path = '.')
      path = path.join(' ') if path.is_a?(Array)
      command('add', path)
    end
    
    def remove(path = '.', opts = {})
      path = path.join(' ') if path.is_a?(Array)

      arr_opts = ['-f']  # overrides the up-to-date check by default
      arr_opts << ['-r'] if opts[:recursive]
      arr_opts << path

      command('rm', arr_opts)
    end

    def commit(message, opts = {})
      arr_opts = ["-m '#{message}'"]
      arr_opts << '-a' if opts[:add_all]
      command('commit', arr_opts)
    end

    def reset(commit, opts = {})
      arr_opts = []
      arr_opts << '--hard' if opts[:hard]
      arr_opts << commit.to_s if commit
      command('reset', arr_opts)
    end

    
    private
    
    def command_lines(cmd, opts = {})
      command(cmd, opts).split("\n")
    end
    
    def command(cmd, opts = {})
      ENV['GIT_DIR'] = @git_dir 
      ENV['GIT_INDEX_FILE'] = @git_index_file 
      ENV['GIT_WORK_DIR'] = @git_work_dir 
      path = @git_work_dir || @git_dir || @path
      Dir.chdir(path) do  
        opts = opts.to_a.join(' ')
        out = `git #{cmd} #{opts} 2>&1`.chomp
        #puts path
        #puts "gd: #{@git_work_dir}"
        #puts "gi: #{@git_index_file}"
        #puts "pp: #{@path}"
        #puts "git #{cmd} #{opts}"
        #puts out
        #puts
        if $?.exitstatus > 1
          raise Git::GitExecuteError.new(out)
        end
        out
      end
    end
    
  end
end