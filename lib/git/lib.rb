require 'tempfile'

module Git
  
  class GitExecuteError < StandardError 
  end
  
  class Lib
      
    @git_dir = nil
    @git_index_file = nil
    @git_work_dir = nil
    @path = nil
    
    @logger = nil
    @raw_repo = nil
    
    def initialize(base = nil, logger = nil)
      if base.is_a?(Git::Base)
        @git_dir = base.repo.path
        @git_index_file = base.index.path if base.index
        @git_work_dir = base.dir.path if base.dir
      elsif base.is_a?(Hash)
        @git_dir = base[:repository]
        @git_index_file = base[:index] 
        @git_work_dir = base[:working_directory]
      end
      if logger
        @logger = logger
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
      arr_opts << "#{opts[:between][0].to_s}..#{opts[:between][1].to_s}" if (opts[:between] && opts[:between].size == 2)
      arr_opts << opts[:object] if opts[:object].is_a? String
      arr_opts << '-- ' + opts[:path_limiter] if opts[:path_limiter].is_a? String
      
      command_lines('log', arr_opts, true).map { |l| l.split.first }
    end
    
    def full_log_commits(opts = {})
      if !(opts[:since] || opts[:between] || opts[:path_limiter])
        # can do this in pure ruby
        sha = revparse(opts[:object] || branch_current || 'master')
        count = opts[:count] || 30
        
        if /\w{40}/.match(sha)  # valid sha
          repo = get_raw_repo
          return process_commit_data(repo.log(sha, count))
        end
      end
      
      arr_opts = ['--pretty=raw']
      arr_opts << "-#{opts[:count]}" if opts[:count]
      arr_opts << "--since=\"#{opts[:since]}\"" if opts[:since].is_a? String
      arr_opts << "#{opts[:between][0].to_s}..#{opts[:between][1].to_s}" if (opts[:between] && opts[:between].size == 2)
      arr_opts << opts[:object] if opts[:object].is_a? String
      arr_opts << '-- ' + opts[:path_limiter] if opts[:path_limiter].is_a? String
      
      full_log = command_lines('log', arr_opts, true)
      process_commit_data(full_log)
    end
    
    def revparse(string)
      if /\w{40}/.match(string)  # passing in a sha - just no-op it
        return string
      end
            
      head = File.join(@git_dir, 'refs', 'heads', string)
      return File.read(head).chomp if File.file?(head)

      head = File.join(@git_dir, 'refs', 'remotes', string)
      return File.read(head).chomp if File.file?(head)
      
      head = File.join(@git_dir, 'refs', 'tags', string)
      return File.read(head).chomp if File.file?(head)
      
      command('rev-parse', string)
    end
    
    def namerev(string)
      command('name-rev', string).split[1]
    end
    
    def object_type(sha)
      command('cat-file', ['-t', sha])
    end
    
    def object_size(sha)
      command('cat-file', ['-s', sha]).to_i
    end

    def get_raw_repo
      @raw_repo ||= Git::Raw::Repository.new(@git_dir)
    end
    
    # returns useful array of raw commit object data
    def commit_data(sha)
      sha = sha.to_s
      cdata = get_raw_repo.cat_file(revparse(sha))
      #cdata = command_lines('cat-file', ['commit', sha])
      process_commit_data(cdata, sha)
    end
    
    def process_commit_data(data, sha = nil)
      in_message = false
            
      if sha
        hsh = {'sha' => sha, 'message' => '', 'parent' => []}
      else
        hsh_array = []        
      end
    
      data.each do |line|
        line = line.chomp
        if in_message && line != ''
          hsh['message'] += line + "\n"
        end

        if (line != '') && !in_message
          data = line.split
          key = data.shift
          value = data.join(' ')
          if key == 'commit'
            sha = value
            hsh_array << hsh if hsh
            hsh = {'sha' => sha, 'message' => '', 'parent' => []}
          end
          if key == 'parent'
            hsh[key] << value
          else
            hsh[key] = value
          end
        elsif in_message && line == ''
          in_message = false
        else
          in_message = true
        end
      end
      
      if hsh_array
        hsh_array << hsh if hsh
        hsh_array
      else
        hsh
      end
    end
    
    def object_contents(sha)
      #command('cat-file', ['-p', sha])
      get_raw_repo.cat_file(revparse(sha)).chomp
    end

    def ls_tree(sha)
      data = {'blob' => {}, 'tree' => {}}
      
      get_raw_repo.object(revparse(sha)).entry.each do |e|
        data[e.format_type][e.name] = {:mode => e.format_mode, :sha => e.sha1}
      end
        
      #command_lines('ls-tree', sha.to_s).each do |line|
      #  (info, filenm) = line.split("\t")
      #  (mode, type, sha) = info.split
      #  data[type][filenm] = {:mode => mode, :sha => sha}
      #end
      
      data
    end

    def branches_all
      head = File.read(File.join(@git_dir, 'HEAD'))
      arr = []
      
      if m = /ref: refs\/heads\/(.*)/.match(head)
        current = m[1]
      end
      arr += list_files('heads').map { |f| [f, f == current] }
      arr += list_files('remotes').map { |f| [f, false] }
      
      #command_lines('branch', '-a').each do |b| 
      #  current = false
      #  current = true if b[0, 2] == '* '
      #  arr << [b.gsub('* ', '').strip, current]
      #end
      
      arr
    end

    def list_files(ref_dir)
      dir = File.join(@git_dir, 'refs', ref_dir)
      files = nil
      Dir.chdir(dir) { files = Dir.glob('**/*').select { |f| File.file?(f) } }
      files
    end
    
    def branch_current
      branches_all.select { |b| b[1] }.first[0] rescue nil
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
      config_list.each do |key, value|
        if /remote.#{name}/.match(key)
          hsh[key.gsub("remote.#{name}.", '')] = value
        end
      end
      hsh
    end

    def config_get(name)
      c = config_list
      c[name]
      #command('config', ['--get', name])
    end
    
    def config_list
      config = {}
      config.merge!(parse_config('~/.gitconfig'))
      config.merge!(parse_config(File.join(@git_dir, 'config')))
      #hsh = {}
      #command_lines('config', ['--list']).each do |line|
      #  (key, value) = line.split('=')
      #  hsh[key] = value
      #end
      #hsh
    end
    
    def parse_config(file)
      hsh = {}
      file = File.expand_path(file)
      if File.file?(file)
        current_section = nil
        File.readlines(file).each do |line|
          if m = /\[(\w+)\]/.match(line)
            current_section = m[1]
          elsif m = /\[(\w+?) "(.*?)"\]/.match(line)
            current_section = "#{m[1]}.#{m[2]}"
          elsif m = /(\w+?) = (.*)/.match(line)
            key = "#{current_section}.#{m[1]}"
            hsh[key] = m[2] 
          end
        end
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


    def branch_new(branch)
      command('branch', branch)
    end
    
    def branch_delete(branch)
      command('branch', ['-d', branch])
    end
    
    def checkout(branch, opts = {})
      arr_opts = []
      arr_opts << '-f' if opts[:force]
      arr_opts << branch.to_s
      
      command('checkout', arr_opts)
    end
    
    def merge(branch, message = nil)      
      arr_opts = []
      arr_opts << ["-m '#{message}'"] if message
      arr_opts << branch.to_a.join(' ')
      command('merge', arr_opts)
    end

    def unmerged
      unmerged = []
      command_lines('diff', ["--cached"]).each do |line|
        unmerged << $1 if line =~ /^\* Unmerged path (.*)/
      end
      unmerged
    end

    def conflicts #yields :file, :your, :their
      self.unmerged.each do |f|
        your = Tempfile.new("YOUR-#{File.basename(f)}").path
        arr_opts = [":2:#{f}", ">#{your}"]
        command('show', arr_opts) 

        their = Tempfile.new("THEIR-#{File.basename(f)}").path
        arr_opts = [":3:#{f}", ">#{their}"]
        command('show', arr_opts) 
        yield(f, your, their)
      end
    end

    def remote_add(name, url, opts = {})
      arr_opts = ['add']
      arr_opts << '-f' if opts[:with_fetch]
      arr_opts << name
      arr_opts << url
      
      command('remote', arr_opts)
    end
    
    # this is documented as such, but seems broken for some reason
    # i'll try to get around it some other way later
    def remote_remove(name)
      command('remote', ['rm', name])
    end
    
    def remotes
      command_lines('remote')
    end

    def tags
      tag_dir = File.join(@git_dir, 'refs', 'tags')
      tags = []
      Dir.chdir(tag_dir) { tags = Dir.glob('*') }
      return tags
      #command_lines('tag')
    end

    def tag(tag)
      command('tag', tag)
    end

    
    def fetch(remote)
      command('fetch', remote.to_s)
    end
    
    def push(remote, branch = 'master')
      command('push', [remote.to_s, branch.to_s])
    end
    
    def tag_sha(tag_name)
      head = File.join(@git_dir, 'refs', 'tags', tag_name)
      return File.read(head).chomp if File.exists?(head)
      
      command('show-ref',  ['--tags', '-s', tag_name])
    end  
    
    def repack
      command('repack', ['-a', '-d'])
    end
    
    # reads a tree into the current index file
    def read_tree(treeish, opts = {})
      arr_opts = []
      arr_opts << "--prefix=#{opts[:prefix]}" if opts[:prefix]
      arr_opts << treeish.to_a.join(' ')
      command('read-tree', arr_opts)
    end
    
    def write_tree
      command('write-tree')
    end
    
    def commit_tree(tree, opts = {})
      opts[:message] = "commit tree #{tree}" if !opts[:message]
      t = Tempfile.new('commit-message') do |t|
        t.write(opts[:message])
      end
      
      arr_opts = []
      arr_opts << tree
      arr_opts << "-p #{opts[:parent]}" if opts[:parent]
      opts[:parents].each { |p| arr_opts << "-p #{p.to_s}" } if opts[:parents]
      arr_opts << "< #{t.path}"
      command('commit-tree', arr_opts)
    end
    
    def update_ref(branch, commit)
      command('update-ref', [branch.to_s, commit.to_s])
    end
    
    def checkout_index(opts = {})
      arr_opts = []
      arr_opts << "--prefix=#{opts[:prefix]}" if opts[:prefix]
      arr_opts << "--force" if opts[:force]
      arr_opts << "--all" if opts[:all]
      arr_opts << ('-- ' + opts[:path_limiter]) if opts[:path_limiter].is_a? String
      command('checkout-index', arr_opts)
    end
    
    # creates an archive file
    #
    # options
    #  :format  (zip, tar)
    #  :prefix
    #  :remote
    #  :path
    def archive(sha, file = nil, opts = {})
      opts[:format] = 'zip' if !opts[:format]
      
      if opts[:format] == 'tgz'
        opts[:format] = 'tar' 
        opts[:add_gzip] = true
      end
      
      if !file
        file = Tempfile.new('archive').path
      end
      
      arr_opts = []
      arr_opts << "--format=#{opts[:format]}" if opts[:format]
      arr_opts << "--prefix=#{opts[:prefix]}" if opts[:prefix]
      arr_opts << "--remote=#{opts[:remote]}" if opts[:remote]
      arr_opts << sha
      arr_opts << opts[:path] if opts[:path]
      arr_opts << '| gzip' if opts[:add_gzip]
      arr_opts << "> #{file.to_s}"
      command('archive', arr_opts)
      return file
    end
    
    private
    
    def command_lines(cmd, opts = [], chdir = true)
      command(cmd, opts, chdir).split("\n")
    end
    
    def command(cmd, opts = [], chdir = true)
      ENV['GIT_DIR'] = @git_dir if (@git_dir != ENV['GIT_DIR'])
      ENV['GIT_INDEX_FILE'] = @git_index_file if (@git_index_file != ENV['GIT_INDEX_FILE'])
      ENV['GIT_WORK_TREE'] = @git_work_dir if (@git_work_dir != ENV['GIT_WORK_TREE'])
      path = @git_work_dir || @git_dir || @path

      opts = opts.to_a.join(' ')
      git_cmd = "git #{cmd} #{opts}"

      out = nil
      if chdir && (Dir.getwd != path)
        Dir.chdir(path) { out = `#{git_cmd} 2>&1`.chomp } 
      else
        out = `#{git_cmd} 2>&1`.chomp
      end
      
      if @logger
        @logger.info(git_cmd)
        @logger.debug(out)
      end
            
      if $?.exitstatus > 0
        if $?.exitstatus == 1 && out == ''
          return ''
        end
        raise Git::GitExecuteError.new(git_cmd + ':' + out.to_s) 
      end
      out
    end
    
  end
end
