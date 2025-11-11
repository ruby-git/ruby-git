# frozen_string_literal: true

require 'rake/clean'

# Load all .rake files from tasks and its subdirectories.
Dir.glob('tasks/**/*.rake').each { |r| load r }

default_tasks = []
default_tasks << :test if Rake::Task.task_defined?(:test)
default_tasks << :rubocop if Rake::Task.task_defined?(:rubocop)
default_tasks << :yard if Rake::Task.task_defined?(:yard)
default_tasks << :'yardstick:coverage' if Rake::Task.task_defined?(:'yardstick:coverage')
# Do not include yardstick as a default task for now since there are too many
# warnings. Will work to get the warnings down before re-enabling it.
# default_tasks << :yardstick if Rake::Task.task_defined?(:yardstick)
default_tasks << :build if Rake::Task.task_defined?(:build)

task default: default_tasks
