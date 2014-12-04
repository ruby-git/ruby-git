require 'date'

require "#{File.expand_path(File.dirname(__FILE__))}/lib/git/version"

Gem::Specification.new do |s|
  s.date = Date.today.to_s
  s.authors = ['Scott Chacon']
  s.email = ['schacon@gmail.com']
  s.homepage = 'http://github.com/schacon/ruby-git'
  s.license = 'MIT'
  s.name = 'git'
  s.summary = 'Ruby/Git is a Ruby library that can be used to create, read and manipulate Git repositories by wrapping system calls to the git binary.'
  s.version = Git::VERSION

  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.require_paths = ['lib']
  s.requirements = ['Git 1.6.0.0 or greater']

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rdoc'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'test-unit'

  s.extra_rdoc_files = %w(History.txt LICENSE.txt README.md)
  s.rdoc_options = ['--charset=UTF-8']

  s.files = Dir.glob File.join('lib', '**', '*.rb')
end
