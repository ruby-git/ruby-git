
# Add the directory containing this file to the start of the load path if it
# isn't there already.
$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'git/base'
require 'git/path'
require 'git/lib'

require 'git/repository'
require 'git/index'
require 'git/working_directory'

require 'git/log'
require 'git/object'

require 'git/branches'
require 'git/branch'
require 'git/remote'

require 'git/diff'
require 'git/status'
require 'git/author'

# Git/Ruby Library
#
# This provides bindings for working with git in complex
# interactions, including branching and merging, object
# inspection and manipulation, history, patch generation
# and more.  You should be able to do most fundamental git
# operations with this library.
#
# This module provides the basic functions to open a git 
# reference to work with. You can open a working directory,
# open a bare repository, initialize a new repo or clone an
# existing remote repository.
#
# Author::    Scott Chacon (mailto:schacon@gmail.com)
# License::   MIT License
module Git

  VERSION = '1.0.4'
  
  # open a bare repository
  #
  # this takes the path to a bare git repo
  # it expects not to be able to use a working directory
  # so you can't checkout stuff, commit things, etc.
  # but you can do most read operations
  def self.bare(git_dir)
    Base.bare(git_dir)
  end
    
  # open an existing git working directory
  # 
  # this will most likely be the most common way to create
  # a git reference, referring to a working directory.
  # if not provided in the options, the library will assume
  # your git_dir and index are in the default place (.git/, .git/index)
  #
  # options
  #   :repository => '/path/to/alt_git_dir'
  #   :index => '/path/to/alt_index_file'
  def self.open(working_dir, options = {})
    Base.open(working_dir, options)
  end

  # initialize a new git repository, defaults to the current working directory
  #
  # options
  #   :repository => '/path/to/alt_git_dir'
  #   :index => '/path/to/alt_index_file'
  def self.init(working_dir = '.', options = {})
    Base.init(working_dir, options)
  end

  # clones a remote repository
  #
  # options
  #   :bare => true (does a bare clone)
  #   :repository => '/path/to/alt_git_dir'
  #   :index => '/path/to/alt_index_file'
  #
  # example
  #  Git.clone('git://repo.or.cz/rubygit.git', 'clone.git', :bare => true)
  #
  def self.clone(repository, name, options = {})
    Base.clone(repository, name, options)
  end
    
end
