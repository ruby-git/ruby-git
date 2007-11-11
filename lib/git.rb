
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
=begin
require 'git/author'
require 'git/file'

require 'git/sha'
require 'git/ref'
=end

module Git
  
  def self.bare(git_dir)
    Base.bare(git_dir)
  end
    
  def self.open(working_dir, options = {})
    Base.open(working_dir, options)
  end

  def self.init(working_dir = '.', options = {})
    Base.init(working_dir, options)
  end

  def self.clone(repository, name, options = {})
    Base.clone(repository, name, options)
  end
    
end
