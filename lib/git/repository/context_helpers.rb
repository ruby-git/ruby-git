# frozen_string_literal: true

require 'fileutils'
require 'pathname'
require 'tmpdir'
require 'git/execution_context/repository'
require 'git/system_call_guard'

module Git
  class Repository
    # Facade methods for block-based directory and index context helpers
    #
    # These helpers allow callers to temporarily change the working directory,
    # the git index, or both, restoring the original state unconditionally when
    # the block exits — even if the block raises an exception.
    #
    # Included by {Git::Repository}.
    #
    # @api private
    #
    module ContextHelpers
      # Changes the current working directory to the repository working directory
      # for the duration of the block
      #
      # @example Write a file inside the repository working directory
      #   repo.chdir do |dir|
      #     File.write('hello.txt', 'Hello, world!')
      #     repo.add('hello.txt')
      #   end
      #
      # @return [Object] the value returned by the block
      #
      # @raise [ArgumentError] if the repository has no working directory (bare
      #   repository)
      #
      # @raise [Git::Error] if the working directory cannot be entered
      #
      # @yield [dir] the repository working directory
      #
      # @yieldparam dir [Pathname] the working directory path
      #
      # @yieldreturn [Object] returned as the method's return value
      #
      def chdir
        raise ArgumentError, 'cannot chdir: repository has no working directory (bare repository)' if dir.nil?

        context_helpers_chdir(dir.to_s) { yield dir }
      end

      # Temporarily switches the git index to `new_index` for the duration of
      # the block
      #
      # Rebuilds the repository execution context to point to the new index file,
      # yields `self`, then unconditionally restores the original execution
      # context — even if the block raises an exception.
      #
      # @example Read a tree into a custom index
      #   repo.with_index('/tmp/custom.index') do
      #     repo.read_tree('HEAD')
      #   end
      #
      # @param new_index [String, Pathname] path to the replacement index file
      #
      # @return [Object] the value returned by the block
      #
      # @yield [repo] the repository instance with the new index active
      #
      # @yieldparam repo [Git::Repository] `self`
      #
      # @yieldreturn [Object] returned as the method's return value
      #
      def with_index(new_index) # :yields: self
        old_context = @execution_context
        set_index(new_index, must_exist: false)
        yield self
      ensure
        @execution_context = old_context
      end

      # Temporarily switches the git index to a new temporary file for the
      # duration of the block, then removes the file
      #
      # The temporary index file does not exist until git creates it on first
      # write. A unique temporary directory is created to hold the index path,
      # avoiding the risk of presenting an empty file to git (which git would
      # reject as a corrupt index). The directory — and any files inside it —
      # are removed unconditionally after the block exits, even if the block
      # raises an exception.
      #
      # @example Stage changes using a temporary index
      #   repo.with_temp_index do
      #     repo.read_tree('HEAD')
      #     repo.write_tree
      #   end
      #
      # @return [Object] the value returned by the block
      #
      # @raise [Git::Error] if the temporary directory cannot be created
      #
      # @yield [repo] the repository instance with the temporary index active
      #
      # @yieldparam repo [Git::Repository] `self`
      #
      # @yieldreturn [Object] returned as the method's return value
      #
      def with_temp_index(&) # :yields: self
        # Use a unique temp directory so the index file path is collision-free
        # and does not exist until git writes it. An existing empty file would
        # be treated as a corrupt index by git.
        temp_dir = context_helpers_mktmpdir('git-temp-index-')
        begin
          with_index(File.join(temp_dir, 'index'), &)
        ensure
          FileUtils.remove_entry(temp_dir, true)
        end
      end

      # Temporarily switches the git working directory to `work_dir` for the
      # duration of the block
      #
      # Rebuilds the repository execution context to point to the new working
      # directory, changes the process working directory via `Dir.chdir`, yields
      # `self`, then unconditionally restores the original execution context —
      # even if the block raises an exception.
      #
      # @example Commit changes from a different worktree path
      #   repo.with_working('/path/to/worktree') do
      #     repo.add('.')
      #     repo.commit('chore: automated update')
      #   end
      #
      # @param work_dir [String, Pathname] path to the replacement working
      #   directory
      #
      # @return [Object] the value returned by the block
      #
      # @raise [ArgumentError] if `work_dir` does not exist on disk
      #
      # @raise [Git::Error] if `work_dir` cannot be entered
      #
      # @yield [repo] the repository instance with the new working directory
      #   active
      #
      # @yieldparam repo [Git::Repository] `self`
      #
      # @yieldreturn [Object] returned as the method's return value
      #
      def with_working(work_dir) # :yields: self
        old_context = @execution_context
        set_working(work_dir)
        context_helpers_chdir(dir.to_s) { yield self }
      ensure
        @execution_context = old_context
      end

      # Temporarily switches the git working directory to a new temporary
      # directory for the duration of the block, then removes the directory and
      # its contents
      #
      # The temporary directory is removed unconditionally after the block
      # exits, even if the block raises an exception.
      #
      # @example Write files in an isolated temporary working directory
      #   repo.with_temp_working do
      #     File.write('scratch.txt', 'temporary content')
      #   end
      #
      # @return [Object] the value returned by the block
      #
      # @raise [Git::Error] if the temporary directory cannot be created or
      #   removed
      #
      # @yield [repo] the repository instance with the temporary working
      #   directory active
      #
      # @yieldparam repo [Git::Repository] `self`
      #
      # @yieldreturn [Object] returned as the method's return value
      #
      def with_temp_working(&) # :yields: self
        Git::SystemCallGuard.call('Failed to create or remove a temporary directory') do |guard|
          Dir.mktmpdir('temp-workdir') { |temp_dir| guard.unguarded { with_working(temp_dir, &) } }
        end
      end

      # Sets the git index to `index_file` and rebuilds the execution context
      #
      # By default raises if `index_file` does not exist. Pass `must_exist:
      # false` to skip the existence check (useful when the index will be
      # created by git later).
      #
      # @example Set the index to a custom path
      #   repo.set_index('/path/to/custom.index')
      #
      # @param index_file [String, Pathname] path to the new index file
      #
      # @param check [Boolean, nil] deprecated positional argument — use
      #   `must_exist:` instead; emits a deprecation warning when non-`nil`
      #
      # @param must_exist [Boolean, nil] when `true` (the default), raises
      #   `ArgumentError` if `index_file` does not exist on disk
      #
      # @return [void]
      #
      # @raise [ArgumentError] if `must_exist: true` (the default) and
      #   `index_file` does not exist
      #
      def set_index(index_file, check = nil, must_exist: nil)
        must_exist = context_helpers_deprecate_check_argument(check, must_exist)
        new_path = context_helpers_validate_path(index_file, must_exist)
        context_helpers_rebuild_context(git_index_file: new_path.to_s)
        nil
      end

      # Sets the git working directory to `work_dir` and rebuilds the execution
      # context
      #
      # By default raises if `work_dir` does not exist. Pass `must_exist:
      # false` to skip the existence check.
      #
      # @example Set the working directory to a custom path
      #   repo.set_working('/path/to/working')
      #
      # @param work_dir [String, Pathname] path to the new working directory
      #
      # @param check [Boolean, nil] deprecated positional argument — use
      #   `must_exist:` instead; emits a deprecation warning when non-`nil`
      #
      # @param must_exist [Boolean, nil] when `true` (the default), raises
      #   `ArgumentError` if `work_dir` does not exist on disk
      #
      # @return [void]
      #
      # @raise [ArgumentError] if `must_exist: true` (the default) and
      #   `work_dir` does not exist
      #
      def set_working(work_dir, check = nil, must_exist: nil)
        must_exist = context_helpers_deprecate_check_argument(check, must_exist)
        new_path = context_helpers_validate_path(work_dir, must_exist)
        context_helpers_rebuild_context(git_work_dir: new_path.to_s)
        nil
      end

      private

      # Runs the block with the process working directory set to `path`
      #
      # A `SystemCallError` from entering or leaving `path` is raised as
      # {Git::Error}. A `SystemCallError` raised by the block propagates
      # unchanged.
      #
      # The message does not name a directory because `Dir.chdir` fails on
      # either leg: entering `path`, or restoring the previous directory
      # afterward. The underlying `SystemCallError` names the directory that
      # actually failed.
      #
      # @param path [String] the directory to enter
      #
      # @return [Object] the value returned by the block
      #
      # @raise [Git::Error] if `path` cannot be entered
      #
      # @yield the code to run inside `path`
      #
      # @yieldreturn [Object] returned as the method's return value
      #
      # @api private
      #
      def context_helpers_chdir(path, &block)
        Git::SystemCallGuard.call('Failed to change directory') do |guard|
          Dir.chdir(path) { guard.unguarded(&block) }
        end
      end

      # Creates a temporary directory, raising {Git::Error} on failure
      #
      # @param prefix [String] the directory name prefix
      #
      # @return [String] the path of the new directory
      #
      # @raise [Git::Error] if the directory cannot be created
      #
      # @api private
      #
      def context_helpers_mktmpdir(prefix)
        Git::SystemCallGuard.call('Failed to create a temporary directory') { Dir.mktmpdir(prefix) }
      end

      # Resolves deprecated `check` argument semantics with `must_exist:`
      #
      # @param check [Boolean, nil] deprecated positional existence-check value
      #
      # @param must_exist [Boolean, nil] keyword existence-check override
      #
      # @return [Boolean] whether path existence must be enforced
      #
      def context_helpers_deprecate_check_argument(check, must_exist)
        if !check.nil? && defined?(Git::Deprecation)
          Git::Deprecation.warn(
            'The "check" argument is deprecated and will be removed in v6.0.0. ' \
            'Use "must_exist:" instead.'
          )
        end
        # Preserve the original Git::Base semantics: when both the deprecated
        # positional `check` and the new `must_exist:` keyword are given, OR
        # them so the more restrictive value wins.
        #
        # NilClass#| is defined in Ruby: nil | false → false, nil | true → true.
        # This means single-argument callers (check only, or must_exist: only)
        # are handled correctly without any nil-special-casing.
        return true if must_exist.nil? && check.nil?

        must_exist | check
      end

      # Expands `path` and validates existence when required
      #
      # @param path [String, Pathname] path to normalize and validate
      #
      # @param must_exist [Boolean] whether the expanded path must already exist
      #
      # @return [Pathname] the expanded absolute path
      #
      # @raise [ArgumentError] if `must_exist` is `true` and the path does not exist
      #
      # @raise [Git::Error] if the path cannot be expanded, which happens when
      #   `path` is relative and the process working directory has been removed
      #
      def context_helpers_validate_path(path, must_exist)
        expanded = Git::SystemCallGuard.call('Failed to expand the path') { File.expand_path(path.to_s) }

        Pathname.new(expanded).tap do |expanded_path|
          raise ArgumentError, "path does not exist: #{expanded_path}" if must_exist && !expanded_path.exist?
        end
      end

      # Rebuilds the repository execution context with selected overrides
      #
      # @param overrides [Hash] execution-context attributes to override
      #
      # @option overrides [String, nil] :git_index_file replacement index file path
      #
      # @option overrides [String, nil] :git_work_dir replacement working directory
      #   path
      #
      # @return [void]
      #
      def context_helpers_rebuild_context(**overrides)
        @execution_context = @execution_context.dup_with(**overrides)
      end
    end
  end
end
