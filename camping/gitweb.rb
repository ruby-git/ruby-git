require 'rubygems'
require 'camping'
require 'git'

# this is meant to be a git-less web head to your git repo
#
# install dependencies
#   sudo gem install camping-omnibus --source http://code.whytheluckystiff.net
#
# author : scott chacon
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
  class Diff < R '/diff/(\d+)/(\w+)'
  end
  class Tree < R '/tree/(\d+)/(\w+)'
  end
  class Archive < R '/archive/(\d+)/(\W+)'
  end
end

module GitWeb::Views
  def layout
    html do
      body do
        self << yield
      end
    end
  end

  def view
    h1 @repo.name
    h2 @repo.path

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
          td log.message[0, 60]
          td { a 'commit', :href => R(Commit, @repo, log.sha) }
          td { a 'diff', :href => R(Diff, @repo, log.sha) }
          td { a 'tree', :href => R(Tree, @repo, log.sha) }
          td { a 'archive', :href => R(Archive, @repo, log.sha) }
        end
      end
    end
    
    h3 'heads'
    @git.branches.each do |branch|
      li branch.full
    end
  end
  
  def commit
    h1 @commit.name
    h2 @commit.sha
    p @commit.message
    p @commit.parent
    p @commit.author.name
    p @commit.author.email
    p @commit.committer.name
    p @commit.committer.email
    p @commit.gtree.sha
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
