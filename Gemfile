# frozen_string_literal: true

source 'https://rubygems.org'

gemspec name: 'git'

# Temporarily source yard-lint from a fork branch that adds the
# Tags/TagSeparator validator (enabled in .yard-lint.yml). Revert to the
# released gem once the validator is merged upstream and published.
# See: https://github.com/mensfeld/yard-lint
#
# Pinned to a specific commit (rather than the branch name) so installs stay
# deterministic while the branch continues to move. Bump this ref
# intentionally: https://github.com/jcouball/yard-lint/tree/feature/tag-separator
#
# Scope this to the same runtimes as the gemspec's yard-lint dependency: it is
# excluded on JRuby (RUBY_PLATFORM == 'java') and TruffleRuby, and requires
# Ruby >= 3.3.
if !(RUBY_PLATFORM == 'java' || RUBY_ENGINE == 'truffleruby') &&
   Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.3.0')
  gem 'yard-lint', git: 'https://github.com/jcouball/yard-lint', ref: 'ef71742f2c88e2c296a20ab25fb4f25a4a384374'
end
