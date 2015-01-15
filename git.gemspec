Gem::Specification.new do |s|
  s.authors = ['Scott Chacon']
  s.date = '2015-01-13' 
  s.email = 'schacon@gmail.com'
  s.homepage = 'http://github.com/schacon/ruby-git'
  s.license = 'MIT'
  s.name = 'git'
  s.summary = 'Ruby/Git is a Ruby library that can be used to create, read and manipulate Git repositories by wrapping system calls to the git binary.'
  s.version = '1.2.9.1'

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ['lib']
  s.requirements = ['git 1.6.0.0, or greater']

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rdoc'
  s.add_development_dependency 'test-unit', '>=2', '< 4'
  
  s.extra_rdoc_files = ['README.md']
  s.rdoc_options = ['--charset=UTF-8']

  s.files = [
    'CHANGELOG',
    'LICENSE',
    'README.md',
    'VERSION',
    'lib/git.rb',
    'lib/git/author.rb',
    'lib/git/base.rb',
    'lib/git/base/factory.rb',
    'lib/git/branch.rb',
    'lib/git/branches.rb',
    'lib/git/config.rb',
    'lib/git/diff.rb',
    'lib/git/index.rb',
    'lib/git/lib.rb',
    'lib/git/log.rb',
    'lib/git/object.rb',
    'lib/git/path.rb',
    'lib/git/remote.rb',
    'lib/git/repository.rb',
    'lib/git/stash.rb',
    'lib/git/stashes.rb',
    'lib/git/status.rb',
    'lib/git/version.rb',
    'lib/git/working_directory.rb'
  ]
end
