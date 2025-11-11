# frozen_string_literal: true

# YARD documentation for this project can NOT be built with JRuby or TruffleRuby.
# This project uses the redcarpet gem which can not be installed on JRuby.
#
unless RUBY_PLATFORM == 'java' || RUBY_ENGINE == 'truffleruby'
  require 'yard'

  YARD::Rake::YardocTask.new
  CLEAN << '.yardoc'
  CLEAN << 'doc'

  require 'yardstick/rake/verify'
  Yardstick::Rake::Verify.new(:'yardstick:coverage') do |t|
    t.threshold = 50
    t.require_exact_threshold = false
  end

  desc 'Run yardstick to check yard docs'
  task :yardstick do
    sh "yardstick 'lib/**/*.rb'"
  end
end
