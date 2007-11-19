require 'fileutils'
require 'benchmark'
require 'rubygems'
require 'ruby-prof'
#require_gem 'git', '1.0.3'
require 'lib/git'

def main
  @wbare = File.expand_path(File.join('tests', 'files', 'working.git'))
  
  in_temp_dir do
    g = Git.clone(@wbare, 'test')
    g.chdir do
      
      n = 40
      result = RubyProf.profile do
      puts "<pre>"
      
      Benchmark.bm(8) do |x|
        run_code(x, 'objects') do
          @commit = g.gcommit('1cc8667014381')
          @tree = g.gtree('1cc8667014381^{tree}')
          @blob = g.gblob('v2.5:example.txt')
          @obj = g.object('v2.5:example.txt')
        end
        
                
        x.report('config  ') do
          n.times do
            c = g.config
            c = g.config('user.email')
            c = g.config('user.email', 'schacon@gmail.com')
          end
        end
        
        x.report('diff    ') do
          n.times do
            g.diff('gitsearch1', 'v2.5').lines
            g.diff('gitsearch1', 'v2.5').stats
            g.diff('gitsearch1', 'v2.5').patch
          end
        end
        
        x.report('path    ') do
          n.times do
            g.dir.readable?
            g.index.readable?
            g.repo.readable?
          end
        end
        
        #------------------
        x.report('status  ') do
          n.times do
            g.status['example.txt'].mode_index
            s = g.status
            s.added
            s.added
          end
        end

        #------------------
        x.report('log     ') do
          n.times do
            log = g.log.between('v2.5').object('example.txt')
            log.size
            log.size
            log.first
            g.log.between('v2.5').object('example.txt').map { |c| c.message }
            g.log.since("2 years ago").map { |c| c.message }
          end
        end

        #------------------
        x.report('branch  ') do
          for i in 1..10 do
            g.checkout('master')
            g.branch('new_branch' + i.to_s).in_branch('test') do
              g.current_branch
              new_file('new_file_' + i.to_s, 'hello')
              g.add
              true
            end
            g.branch('new_branch').merge('new_branch' + i.to_s)
            g.checkout('new_branch')
          end
        end
        
        #------------------
        x.report('tree    ') do
          for i in 1..10 do
            tr = g.with_temp_index do
               g.read_tree('new_branch' + i.to_s)
               index = g.ls_files
               g.write_tree
             end
          end
        end rescue nil

        x.report('archive ') do
          n.times do
            f = g.gcommit('v2.6').archive # returns path to temp file
          end
        end rescue nil
   
	     
      end
    
      end

      # Print a graph profile to text
      puts "</pre>"
      printer = RubyProf::GraphHtmlPrinter.new(result)
      printer.print(STDOUT, 1)
      printer = RubyProf::FlatPrinter.new(result)
      puts "<pre>"
      printer.print(STDOUT, 1)
      puts "</pre>"
    end
  end
end


def run_code(x, name, times = 30)
  #result = RubyProf.profile do

    x.report(name) do
      for i in 1..times do
        yield i
      end
    end
  
  #end
  
  # Print a graph profile to text
  #printer = RubyProf::FlatPrinter.new(result)
  #printer.print(STDOUT, 0)
end

def new_file(name, contents)
  File.open(name, 'w') do |f|
    f.puts contents
  end
end


def in_temp_dir(remove_after = true)
  filename = 'git_test' + Time.now.to_i.to_s + rand(300).to_s.rjust(3, '0')
  tmp_path = File.join("/tmp/", filename)
  FileUtils.mkdir(tmp_path)
  Dir.chdir tmp_path do
    yield tmp_path
  end
  FileUtils.rm_r(tmp_path) if remove_after
end

main()
