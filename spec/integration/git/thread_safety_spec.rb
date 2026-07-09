# frozen_string_literal: true

require 'spec_helper'

# Git.init sets process-global environment variables (GIT_DIR, GIT_WORK_TREE,
# GIT_INDEX_FILE) for the duration of each git invocation. This integration test
# verifies that concurrent calls to Git.init from multiple threads do not corrupt
# each other's repository state via shared process environment.

RSpec.describe Git, :integration do
  describe '.init' do
    context 'when called concurrently from multiple threads for separate bare repositories' do
      let(:repo_dirs) { Array.new(5) { Dir.mktmpdir } }

      after { repo_dirs.each { |dir| FileUtils.rm_rf(dir) } }

      it 'initializes each repository independently without cross-thread interference' do
        # Use a barrier (Queue) so all threads attempt Git.init at roughly the
        # same time, maximizing the chance of exposing cross-thread interference.
        # Thread#value (rather than #join) re-raises any exception the thread
        # raised, so a regression fails the example instead of being silently
        # swallowed.
        barrier = Queue.new
        threads = repo_dirs.map do |dir|
          Thread.new do
            barrier.pop
            Git.init(dir, bare: true, initial_branch: 'main')
          end
        end
        repo_dirs.size.times { barrier << true }
        threads.each(&:value)

        expect(repo_dirs).to all(satisfy { |dir| File.exist?(File.join(dir, 'HEAD')) })
      end
    end
  end
end
