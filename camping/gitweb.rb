require 'rubygems'
require 'camping'
require 'git'

begin
  require 'syntax/convertors/html'
rescue LoadError
end

# this is meant to be a git-less web head to your git repo
#
# install dependencies
#   sudo gem install camping-omnibus --source http://code.whytheluckystiff.net
#
# author : scott chacon
# thanks to dr. nic for his syntax code highlighting deal
#
# /usr/local/lib/ruby/gems/1.8/gems/camping-1.5.180/examples/

Camping.goes :GitWeb

module GitWeb::Models
  class Repository < Base; end
  
  class CreateGitWeb < V 0.1
    def self.up
      create_table :gitweb_repositories, :force => true do |t|
        t.column :name,  :string 
        t.column :path,  :string 
        t.column :bare,  :boolean 
      end
    end
  end
end

module GitWeb::Controllers
  class Index < R '/'
    def get
      @repos = Repository.find :all
      render :index
    end
  end
  
  class Stylesheet < R '/css/highlight.css'
    def get
      @headers['Content-Type'] = 'text/css'
      ending = File.read(__FILE__).gsub(/.*__END__/m, '')
      ending.gsub(/__END__.*/m, '')
    end
  end
  
  class JsHighlight < R '/js/highlight.js'
    def get
      @headers['Content-Type'] = 'text/css'
      File.read(__FILE__).gsub(/.*__JS__/m, '')
    end
  end
  
  class View < R '/view/(\d+)'
    def get repo_id
      @repo = Repository.find repo_id
      @git = Git.bare(@repo.path)      
      render :view
    end
  end
  
  class Fetch < R '/git/(\d+)'
    def get repo_id
      @repo = Repository.find repo_id
      @git = Git.bare(@repo.path)
    end
  end
  
  class Add < R '/add'
    def get
      @repo = Repository.new
      render :add
    end
    def post
      if Git.bare(input.repository_path)
        repo = Repository.create :name => input.repo_name, :path => input.repo_path, :bare => input.repo_bare
        redirect View, repo
      else
        redirect Index
      end
    end
  end

  class Commit < R '/commit/(\d+)/(\w+)'
    def get repo_id, sha
      @repo = Repository.find repo_id
      @git = Git.bare(@repo.path)      
      @commit = @git.gcommit(sha)
      render :commit
    end
  end
  
  class Tree < R '/tree/(\d+)/(\w+)'
    def get repo_id, sha
      @repo = Repository.find repo_id
      @git = Git.bare(@repo.path)      
      @tree = @git.gtree(sha)
      render :tree
    end
  end
  
  class Blob < R '/blob/(\d+)/(.*?)/(\w+)'
    def get repo_id, file, sha
      @repo = Repository.find repo_id
      @git = Git.bare(@repo.path)      
      @blob = @git.gblob(sha)
      @file = file
      render :blob
    end
  end  
  
  class BlobRaw < R '/blob/(\d+)/(\w+)'
     def get repo_id, sha
       @repo = Repository.find repo_id
       @git = Git.bare(@repo.path)      
       @blob = @git.gblob(sha)
       @blob.contents
     end
  end
  
  class Archive < R '/archive/(\d+)/(\w+)'
    def get repo_id, sha
      @repo = Repository.find repo_id
      @git = Git.bare(@repo.path)
      
      file = @git.gtree(sha).archive
      @headers['Content-Type'] = 'application/zip'
      @headers["Content-Disposition"] = "attachment; filename=archive.zip"
      File.new(file).read
    end
  end
  
  class Diff < R '/diff/(\d+)/(\w+)/(\w+)'
    def get repo_id, tree1, tree2
      @repo = Repository.find repo_id
      @git = Git.bare(@repo.path)
      @tree1 = tree1
      @tree2 = tree2
      @diff = @git.diff(tree1, tree2)
      render :diff
    end
  end
  
  class Patch < R '/patch/(\d+)/(\w+)/(\w+)'
    def get repo_id, tree1, tree2
      @repo = Repository.find repo_id
      @git = Git.bare(@repo.path)
      @diff = @git.diff(tree1, tree2).patch
    end
  end
  
end

module GitWeb::Views
  def layout
    html do
      head do
        title 'gitweb'
        #link :href=>R(Stylesheet), :rel=>'stylesheet', :type=>'text/css'
        #script :type => "text/javascript", :language => "JavaScript", :src => R(JsHighlight)
      end
      style <<-END, :type => 'text/css'
        body { color: #333; }
        h1 { background: #cce; padding: 10px; margin: 3px; }
        h3 { background: #aea; padding: 5px; margin: 3px; }
        .options { float: right; margin: 10px; }
        p { padding: 5px; }
        .odd { background: #eee; }
        .tag { margin: 5px; padding: 1px 3px; border: 1px solid #8a8; background: #afa;}
        .indent { padding: 0px 15px;}
        .tip { border-top: 1px solid #aaa; color: #666; padding: 10px; }
      END
      body do
        self << yield
      end
    end
  end

  def view
    h1 @repo.name
    h2 @repo.path

    @tags = {}
    @git.tags.each { |tag| @tags[tag.sha] ||= []; @tags[tag.sha] << tag.name }
        
    url = 'http:' + URL(Fetch, @repo.id).to_s

    h3 'info'
    table.info do
      tr { td 'owner: '; td @git.config('user.name') }
      tr { td 'email: '; td @git.config('user.email') }
      tr { td 'url: '; td { a url, :href => url } }
    end
    
    h3 'shortlog'
    table.shortlog do
      @git.log.each do |log|
        tr do
          td log.date.strftime("%Y-%m-%d")
          td log.sha[0, 8]
          td { em log.author.name }
          td do
            span.message log.message[0, 60]
            @tags[log.sha].each do |t|
              span.space ' '
              span.tag { code t }
            end if @tags[log.sha]
          end
          td { a 'commit', :href => R(Commit, @repo, log.sha) }
          td { a 'commit-diff', :href => R(Diff, @repo, log.sha, log.parent.sha) }
          td { a 'tree', :href => R(Tree, @repo, log.gtree.sha) }
          td { a 'archive', :href => R(Archive, @repo, log.gtree.sha) }
        end
      end
    end
    
    h3 'branches'
    @git.branches.each do |branch|
      li { a branch.full, :href => R(Commit, @repo, branch.gcommit.sha) }
    end
    
    h3 'tags'
    @git.tags.each do |tag|
      li { a tag.name, :href => R(Commit, @repo, tag.sha) }
    end
    
  end
  
  def commit
    a.options 'repo', :href => R(View, @repo)
    h1 @commit.name
    h3 'info'
    table.info do
      tr { td 'author: '; td @commit.author.name + ' <' + @commit.author.email + '>'}
      tr { td ''; td { code @commit.author.date } }
      tr { td 'committer: '; td @commit.committer.name + ' <' + @commit.committer.email + '>'}
      tr { td ''; td { code @commit.committer.date } }
      tr { td 'commit sha: '; td { code @commit.sha } }
      tr do
        td 'tree sha: '
        td do 
          code { a @commit.gtree.sha, :href => R(Tree, @repo, @commit.gtree.sha) }
          span.space ' '
          a 'archive', :href => R(Archive, @repo, @commit.gtree.sha)
        end
      end
      tr do
        td 'parents: '
        td do
          @commit.parents.each do |p|
            code { a p.sha, :href => R(Commit, @repo, p.sha) }
            span.space ' '
            a 'diff', :href => R(DiffTwo, @repo, p.sha, @commit.sha)
            span.space ' '
            a 'archive', :href => R(Archive, @repo, p.gtree.sha)            
            br
          end
        end
      end
    end
    h3 'commit message'
    p @commit.message
  end
  
  def tree
    a.options 'repo', :href => R(View, @repo)
    h3 'tree : ' + @tree.sha
    p { a 'archive tree', :href => R(Archive, @repo, @tree.sha) }; 
    table do
      @tree.children.each do |file, node|
        tr :class => cycle('odd','even') do
          td { code node.sha[0, 8] }
          td node.mode
          td file
          if node.type == 'tree'
            td { a node.type, :href => R(Tree, @repo, node.sha) }
            td { a 'archive', :href => R(Archive, @repo, node.sha) }
          else
            td { a node.type, :href => R(Blob, @repo, file, node.sha) }
            td { a 'raw', :href => R(BlobRaw, @repo, node.sha) }
          end
        end
      end
    end 
  end

  def blob
    link :rel => "stylesheet", :type => "text/css",  
          :href => "http://drnicwilliams.com/external/CodeHighlighter/styles.css"
    script :src => "http://drnicwilliams.com/external/CodeHighlighter/clean_tumblr_pre.js"
    
    ext = File.extname(@file).gsub('.', '')
    ext = 'ruby' if ext == 'rb'
    
    a.options 'repo', :href => R(View, @repo)
    h3 'blob : ' + @blob.sha
    h4 @file
    pre { code @blob.contents, :class => ext }
  end
  
  def diff
    a.options 'repo', :href => R(View, @repo)    
    h1 "diff"

    p { a 'download patch file', :href => R(Patch, @repo, @tree1, @tree2) }

    p do
      a @tree1, :href => R(Tree, @repo, @tree1)
      span.space ' : '
      a @tree2, :href => R(Tree, @repo, @tree2)
    end
  
    @diff.each do |file|
      h3 file.path
      begin
        convertor = Syntax::Convertors::HTML.for_syntax "diff"
        self << convertor.convert( file.patch )
      rescue
        div.indent { pre file.patch }
        div.tip 'tip: if you run "gem install syntax", this will be highlighted'
      end
    end
    
  end
  
  
  def cycle(v1, v2)
    (@value == v1) ? @value = v2 : @value = v1
    @value
  end
  
  def add
    _form(@repo)
  end
  
  def _form(repo)
    form(:method => 'post') do
      label 'Path', :for => 'repo_path'; br
      input :name => 'repo_path', :type => 'text', :value => repo.path; br

      label 'Name', :for => 'repo_name'; br
      input :name => 'repo_name', :type => 'text', :value => repo.name; br

      label 'Bare', :for => 'repo_bare'; br
      input :type => 'checkbox', :name => 'repo_bare', :value => repo.bare; br

      input :type => 'hidden', :name => 'repo_id', :value => repo.id
      input :type => 'submit'
    end
  end
  
  def index
    @repos.each do | repo |
      h1 repo.name
      a repo.path, :href => R(View, repo.id)
    end
    br
    br
    a 'add new repo', :href => R(Add)
  end
end

def GitWeb.create
  GitWeb::Models.create_schema
end