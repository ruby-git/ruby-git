$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'git/version'

Gem::Specification.new do |spec|
  spec.author = 'Scott Chacon and others'
  spec.email = 'schacon@gmail.com'
  spec.homepage = 'http://github.com/ruby-git/ruby-git'
  spec.license = 'MIT'
  spec.name = 'git'
  spec.summary = 'An API to create, read, and manipulate Git repositories'
  spec.description = <<~DESCRIPTION
    The git gem provides an API that can be used to
    create, read, and manipulate Git repositories by wrapping system calls to the git
    command line. The API can be used for working with Git in complex interactions
    including branching and merging, object inspection and manipulation, history, patch
    generation and more.
  DESCRIPTION
  spec.version = Git::VERSION


  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "https://rubydoc.info/gems/#{spec.name}/#{spec.version}/file/CHANGELOG.md"
  spec.metadata['documentation_uri'] = "https://rubydoc.info/gems/#{spec.name}/#{spec.version}"

  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 3.2.0'
  spec.requirements = ['git 2.28.0 or greater']

  spec.add_runtime_dependency 'activesupport', '>= 5.0'
  spec.add_runtime_dependency 'addressable', '~> 2.8'
  spec.add_runtime_dependency 'process_executer', '~> 4.0'
  spec.add_runtime_dependency 'rchardet', '~> 1.9'

  spec.add_development_dependency 'create_github_release', '~> 2.1'
  spec.add_development_dependency 'minitar', '~> 1.0'
  spec.add_development_dependency 'mocha', '~> 2.7'
  spec.add_development_dependency 'rake', '~> 13.2'
  spec.add_development_dependency 'test-unit', '~> 3.6'

  unless RUBY_PLATFORM == 'java'
    spec.add_development_dependency 'redcarpet', '~> 3.6'
    spec.add_development_dependency 'yard', '~> 0.9', '>= 0.9.28'
    spec.add_development_dependency 'yardstick', '~> 0.9'
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(tests|spec|features|bin)/}) }
  end
end
