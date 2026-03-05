# frozen_string_literal: true

require 'rake/clean'

# Load all .rake files from tasks and its subdirectories.
Dir.glob('tasks/**/*.rake').each { |r| load r }

desc 'Run all tests (TestUnit and RSpec)'
task 'test-all': %i[test spec]

desc 'Run all tests in parallel (TestUnit and RSpec run concurrently)'
task 'test-all:parallel' do
  errors = []
  mutex = Mutex.new
  threads = %w[test:parallel spec:parallel].map do |t|
    Thread.new do
      Rake::Task[t].invoke
    rescue Exception => e # rubocop:disable Lint/RescueException
      mutex.synchronize { errors << e }
    end
  end
  threads.each(&:join)
  raise errors.first if errors.any?
end

default_tasks = %i[test spec:unit spec:integration rubocop]
default_tasks << :yard if Rake::Task.task_defined?(:yard)
default_tasks << :build

task default: default_tasks

default_parallel = %w[test:parallel spec:unit:parallel spec:integration:parallel rubocop]
default_parallel << :yard if Rake::Task.task_defined?(:yard)
default_parallel << :build

desc 'Same as default but runs tests in parallel'
task 'default:parallel': default_parallel

module Rake
  # Overload Rake::Task to add logging
  class Task
    # Store the original execute method
    alias original_execute execute

    # Override execute to add a print statement
    def execute(args = nil)
      # Only output the task name if it wasn't the only top-level task
      # rake default      # => output task name for each task called by the default task
      # rake rubocop      # => do not output the task name
      # rake rubocop yard # => output task name for rubocop and yard
      top_level_tasks = Rake.application.top_level_tasks
      box("Rake task: #{name}") unless top_level_tasks.length == 1 && name == top_level_tasks[0]
      original_execute(args)
    end

    private

    def box(message)
      width = message.length + 2
      puts "┌#{'─' * width}┐"
      puts "│ #{message} │"
      puts "└#{'─' * width}┘"
    end
  end
end
