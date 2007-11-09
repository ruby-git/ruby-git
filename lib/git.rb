
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

require 'git/branch'

=begin


require 'git/author'
require 'git/ref'
require 'git/file'

require 'git/sha'
require 'git/diff'

require 'git/remote'
=end

module Git

  def self.repo(git_dir)
    Base.repo(git_dir)
  end
    
  def self.open(working_dir, options = {})
    Base.open(working_dir, options)
  end

  def clone
    Base.clone()
  end

  def init(working_dir = '.')
    Base.clone()
  end
  
end
