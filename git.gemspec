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

  # Not every development dependency is installed on every runtime. Each predicate
  # below names one reason for holding a gem back, which keeps the dependency list
  # itself a flat, readable list. Deriving one predicate from another also keeps
  # coupled gems from drifting apart when a condition changes.
  #
  # These are local variables rather than methods deliberately. The Gemfile uses
  # `gemspec`, so Bundler evaluates this file on every `bundle exec`, and a top-level
  # `def` -- including one written inside this block, since a block is not a definition
  # scope -- would define a private method on Object in every one of those processes.

  # JRuby (which reports RUBY_PLATFORM as 'java') and TruffleRuby build no C extensions
  # and do not run the docs build.
  mri = !(RUBY_PLATFORM == 'java' || RUBY_ENGINE == 'truffleruby')

  # irb stopped being a default gem in Ruby 3.4. JRuby and TruffleRuby ship their own.
  install_irb = mri

  # Ruby 4.0.0 dropped fiddle from the default gems. On Windows, irb loads
  # reline/io/windows.rb, which requires fiddle/import for the Win32 console API, so
  # bin/console cannot start without it; every other platform takes reline's ANSI IO
  # gate and never loads that file. Derived from install_irb because fiddle exists only
  # to serve irb and, being a C extension, could not install where irb is not.
  install_fiddle = install_irb && Gem.win_platform?

  # The docs toolchain is supported on MRI only. redcarpet, YARD's Markdown renderer,
  # is also a C extension and so could not install on JRuby regardless.
  install_docs = mri

  # yard-lint requires Ruby >= 3.3.
  install_yard_lint = install_docs && Gem.ruby_version >= Gem::Version.new('3.3.0')

  # i18n 1.15+ uses Fiber.[] (Ruby 3.2 Fiber storage), which TruffleRuby < 34.0.0 does
  # not implement, so those runtimes hold at the last release that works there.
  pin_old_i18n = RUBY_ENGINE == 'truffleruby' &&
                 Gem::Version.new(RUBY_ENGINE_VERSION) < Gem::Version.new('34.0.0')

  spec.add_development_dependency 'create_github_release', '~> 2.1'
  spec.add_development_dependency 'fiddle', '~> 1.1' if install_fiddle
  spec.add_development_dependency 'fuubar', '~> 2.5'
  spec.add_development_dependency 'i18n', '< 1.15' if pin_old_i18n
  spec.add_development_dependency 'irb', '~> 1.16' if install_irb
  spec.add_development_dependency 'main_branch_shared_rubocop_config', '~> 0.1'
  spec.add_development_dependency 'parallel_tests', '~> 5.6'
  spec.add_development_dependency 'rake', '~> 13.3'
  spec.add_development_dependency 'redcarpet', '~> 3.6' if install_docs
  spec.add_development_dependency 'rspec', '~> 3.13'
  spec.add_development_dependency 'rubocop', '~> 1.82'
  spec.add_development_dependency 'simplecov', '~> 1.0'
  spec.add_development_dependency 'simplecov-lcov', '~> 0.9'
  spec.add_development_dependency 'simplecov-rspec', '~> 1.1'
  spec.add_development_dependency 'yard', '~> 0.9', '>= 0.9.28' if install_docs
  spec.add_development_dependency 'yard_example_test', '~> 0.2', '>= 0.2.1' if install_docs
  spec.add_development_dependency 'yard-lint', '~> 1.8' if install_yard_lint

  # Specify which files should be added to the gem when it is released.
  #
  # This is an allowlist rather than a denylist. A denylist admitted every new
  # development-only path by default, so the gem shipped `.github/`, `redesign/`, the
  # husky hooks, and -- the reason this became an allowlist -- the `.claude/skills`
  # symlink. Extracting a symlink needs a privilege that Windows grants only under
  # Developer Mode or an elevated shell, so installing the gem there either failed
  # outright or, on RubyGems new enough to fall back to a copy, silently duplicated
  # the whole skills tree into the installed gem.
  #
  # spec/unit/gemspec_spec.rb guards both directions: nothing in the list may be a
  # symlink, and every tracked file under lib/ must be present, so the allowlist
  # cannot quietly drop runtime code.
  #
  # doc_files must stay in sync with the extra files named in .yardopts -- those are
  # what rubydoc.info renders for the published documentation, so a file listed there
  # but absent from the gem becomes a broken link.
  doc_files = %w[
    AI_POLICY.md
    CHANGELOG.md
    CODE_OF_CONDUCT.md
    CONTRIBUTING.md
    GOVERNANCE.md
    LICENSE
    MAINTAINERS.md
    README.md
    UPGRADING.md
  ]

  # .yardopts drives the rubydoc.info build; the gemspec is included by convention.
  build_files = %w[.yardopts git.gemspec]

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").select do |f|
      f.start_with?('lib/') || doc_files.include?(f) || build_files.include?(f)
    end
  end
end
