# frozen_string_literal: true

# RuboCop analyzes source text, so its verdict is fixed by TargetRubyVersion in
# .rubocop.yml, not by the host Ruby. Skipping it on JRuby and TruffleRuby loses no
# coverage (the MRI matrix jobs lint the same files) and avoids RuboCop internal
# cop errors on TruffleRuby.
#
unless RUBY_PLATFORM == 'java' || RUBY_ENGINE == 'truffleruby'
  require 'rubocop/rake_task'

  RuboCop::RakeTask.new
end
