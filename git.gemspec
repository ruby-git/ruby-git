# frozen_string_literal: true

# Read the version out of lib/git/version.rb rather than requiring it.
#
# The Gemfile uses `gemspec`, so Bundler evaluates this file on every `bundle exec`.
# `require`ing lib/git/version.rb here would therefore load it before SimpleCov
# starts in spec_helper, leaving it invisible to the coverage report -- an
# unmeasured hole in the 100% coverage gate. See the "Test coverage policy" section
# of CONTRIBUTING.md.
#
# release-please rewrites the `VERSION = '...'` assignment in place (see
# `version-file` in .release-please-config.json), so matching on it stays correct
# across releases. If the match ever fails, the raise below stops the build
# immediately rather than letting a nil version reach the specification.
version = File.read(File.expand_path('lib/git/version.rb', __dir__))[/^\s*VERSION\s*=\s*['"]([^'"]+)['"]/, 1]
raise 'Could not determine Git::VERSION from lib/git/version.rb' if version.nil?

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
  spec.version = version

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "https://rubydoc.info/gems/#{spec.name}/#{spec.version}/file/CHANGELOG.md"
  spec.metadata['documentation_uri'] = "https://rubydoc.info/gems/#{spec.name}/#{spec.version}"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 3.2.0'
  spec.requirements = ['git 2.28.0 or greater']

  spec.add_dependency 'activesupport', '>= 5.0'
  spec.add_dependency 'addressable', '~> 2.8'
  spec.add_dependency 'process_executer', '~> 4.0'
  spec.add_dependency 'rchardet', '~> 1.9'

  spec.add_development_dependency 'create_github_release', '~> 2.1'
  spec.add_development_dependency 'fuubar', '~> 2.5'
  spec.add_development_dependency 'main_branch_shared_rubocop_config', '~> 0.1'
  spec.add_development_dependency 'parallel_tests', '~> 5.6'
  spec.add_development_dependency 'rake', '~> 13.3'
  spec.add_development_dependency 'rspec', '~> 3.13'
  spec.add_development_dependency 'rubocop', '~> 1.82'
  spec.add_development_dependency 'simplecov', '~> 1.0'
  spec.add_development_dependency 'simplecov-lcov', '~> 0.9'
  spec.add_development_dependency 'simplecov-rspec', '~> 1.1'

  if RUBY_ENGINE == 'truffleruby' && Gem::Version.new(RUBY_ENGINE_VERSION) < Gem::Version.new('34.0.0')
    # i18n 1.15+ uses Fiber.[] (Ruby 3.2 Fiber storage) which TruffleRuby < 34.0.0 does not implement
    spec.add_development_dependency 'i18n', '< 1.15'
  end

  unless RUBY_PLATFORM == 'java' || RUBY_ENGINE == 'truffleruby'
    spec.add_development_dependency 'irb', '~> 1.16'
    spec.add_development_dependency 'redcarpet', '~> 3.6'
    spec.add_development_dependency 'yard', '~> 0.9', '>= 0.9.28'
    spec.add_development_dependency 'yard_example_test', '~> 0.2', '>= 0.2.1'

    # yard-lint requires Ruby >= 3.3, so it is only installed on Ruby 3.3+.
    spec.add_development_dependency 'yard-lint', '~> 1.8' if Gem.ruby_version >= Gem::Version.new('3.3.0')
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(tests|spec|features|bin)/}) }
  end
end
