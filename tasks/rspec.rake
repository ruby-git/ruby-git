# frozen_string_literal: true

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new

CLEAN << 'coverage'
CLEAN << '.rspec_status'
CLEAN << 'rspec-report.xml'
