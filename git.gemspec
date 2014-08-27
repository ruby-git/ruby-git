# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'date'
require 'git/version'

Gem::Specification.new do |s|
  s.authors = ['Scott Chacon']
  s.date = Date.today.to_s
  s.email = 'schacon@gmail.com'
  s.homepage = 'http://github.com/schacon/ruby-git'
  s.license = 'MIT'
  s.name = 'git'
  s.summary = 'Ruby/Git is a Ruby library that can be used to create, read and manipulate Git repositories by wrapping system calls to the git binary.'
  s.version = Git::VERSION

  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.require_paths = ['lib']
  s.requirements = ['git 1.6.0.0, or greater']

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rdoc'
  s.add_development_dependency 'test-unit'

  s.extra_rdoc_files = ['README.md']
  s.rdoc_options = ['--charset=UTF-8']

  s.files = `git ls-files -z`.split("\x0")
  # s.executables = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files = s.files.grep(%r{^(test|spec|features)/})
end
