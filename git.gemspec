$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'git/version'

Gem::Specification.new do |s|
  s.author = 'Scott Chacon and others'
  s.email = 'schacon@gmail.com'
  s.homepage = 'http://github.com/ruby-git/ruby-git'
  s.license = 'MIT'
  s.name = 'git'
  s.summary = 'An API to create, read, and manipulate Git repositories'
  s.description = <<~DESCRIPTION
    The git gem provides an API that can be used to
    create, read, and manipulate Git repositories by wrapping system calls to the git
    command line. The API can be used for working with Git in complex interactions
    including branching and merging, object inspection and manipulation, history, patch
    generation and more.
  DESCRIPTION
  s.version = Git::VERSION


  s.metadata['homepage_uri'] = s.homepage
  s.metadata['source_code_uri'] = s.homepage
  s.metadata['changelog_uri'] = "https://rubydoc.info/gems/#{s.name}/#{s.version}/file/CHANGELOG.md"
  s.metadata['documentation_uri'] = "https://rubydoc.info/gems/#{s.name}/#{s.version}"

  s.require_paths = ['lib']
  s.required_ruby_version = '>= 3.0.0'
  s.requirements = ['git 2.28.0 or greater']

  s.add_runtime_dependency 'activesupport', '>= 5.0'
  s.add_runtime_dependency 'addressable', '~> 2.8'
  s.add_runtime_dependency 'process_executer', '~> 1.1'
  s.add_runtime_dependency 'rchardet', '~> 1.8'

  s.add_development_dependency 'create_github_release', '~> 1.4'
  s.add_development_dependency 'minitar', '~> 0.9'
  s.add_development_dependency 'mocha', '~> 2.1'
  s.add_development_dependency 'rake', '~> 13.1'
  s.add_development_dependency 'test-unit', '~> 3.6'

  unless RUBY_PLATFORM == 'java'
    s.add_development_dependency 'redcarpet', '~> 3.6'
    s.add_development_dependency 'yard', '~> 0.9', '>= 0.9.28'
    s.add_development_dependency 'yardstick', '~> 0.9'
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  s.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(tests|spec|features|bin)/}) }
  end
end
