# frozen_string_literal: true

require 'bundler/gem_tasks'

# Make it so that calling `rake release` just calls `rake release:rubygem_push` to
# avoid creating and pushing a new tag.

Rake::Task['release'].clear
desc 'Customized release task to avoid creating a new tag'
task release: 'release:rubygem_push'
