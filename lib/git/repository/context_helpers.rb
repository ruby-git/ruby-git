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
    # The `with_*` helpers build a second {Git::Repository} bound to a different
    # index file or working directory, yield it, and leave the receiver bound to
    # its original index and working directory. Nothing on the receiver changes,
    # so nothing on it is restored when the block exits. The working directory
    # variants change the process working directory for the duration of the
    # block and change it back afterward. The temporary variants remove the
    # scratch directory they created, even if the block raises an exception.
    #
    # The second repository is built with `self.class.new(execution_context:)`,
    # so a subclass of {Git::Repository} must accept that constructor call for
    # the helpers to yield an instance of the subclass.
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

      # Yields a repository bound to `new_index` in place of the receiver's index
      #
      # Yields a second repository bound to `new_index`; its working directory
      # and git directory are the receiver's. The receiver is not changed, so
      # calls on it inside the block still use the original index.
      #
      # @example Read a tree into a custom index
      #   repo.with_index('/tmp/custom.index') do |indexed|
      #     indexed.read_tree('HEAD')
      #   end
      #
      # @param new_index [String, Pathname] path to the replacement index file
      #
      # @return [Object] the value returned by the block
      #
      # @raise [Git::Error] if `new_index` cannot be expanded to an absolute path
      #
      # @yield [repo] the repository bound to `new_index`
      #
      # @yieldparam repo [Git::Repository] a new repository of the receiver's
      #   class bound to `new_index`
      #
      # @yieldreturn [Object] returned as the method's return value
      #
      def with_index(new_index)
        new_path = context_helpers_validate_path(new_index, false)
        yield context_helpers_derived_repository(git_index_file: new_path.to_s)
      end

      # Yields a repository bound to a new temporary index file, then removes
      # the file
      #
      # The temporary index file does not exist until git creates it on first
      # write. A unique temporary directory is created to hold the index path,
      # avoiding the risk of presenting an empty file to git (which git would
      # reject as a corrupt index). The directory, and any files inside it, are
      # removed unconditionally after the block exits, even if the block raises
      # an exception. The yielded repository is bound as {#with_index} binds it.
      #
      # @example Write a tree from a temporary index
      #   tree_sha = repo.with_temp_index do |indexed|
      #     indexed.read_tree('HEAD')
      #     indexed.add('generated.txt')
      #     indexed.write_tree
      #   end
      #
      # @return [Object] the value returned by the block
      #
      # @raise [Git::Error] if the temporary directory cannot be created
      #
      # @yield [repo] the repository bound to the temporary index
      #
      # @yieldparam repo [Git::Repository] a new repository of the receiver's
      #   class bound to an index file inside the temporary directory
      #
      # @yieldreturn [Object] returned as the method's return value
      #
      # @note The yielded repository stays bound to the temporary index path
      #   after the directory that held it is removed. Do not let it, or an
      #   object that holds it and later runs commands against the index,
      #   escape the block. Git treats the missing index file as an empty
      #   index, so reads such as {Git::Repository::StatusOperations#ls_files}
      #   return nothing and {Git::Repository::StatusOperations#status_info}
      #   reports every tracked file both as deleted and as untracked; writes
      #   such as {Git::Repository::Staging#add} raise {Git::Error}. Reads from
      #   the object database, such as {Git::Object::AbstractObject#contents},
      #   still work.
      #
      def with_temp_index(&)
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

      # Yields a repository bound to `work_dir` in place of the receiver's
      # working directory
      #
      # Yields a second repository bound to `work_dir`. It shares the
      # receiver's index and git directory, so staging through it changes what
      # the receiver sees as staged. The process working directory is changed
      # to `work_dir` via `Dir.chdir` for the duration of the block and changed
      # back afterward. The receiver is not changed, so calls on it inside the
      # block still use the original working directory.
      #
      # `Dir.chdir` is process-global, so this method is not safe to call from
      # more than one thread at a time.
      #
      # @example Commit changes from a different worktree path
      #   repo.with_working('/path/to/worktree') do |worktree|
      #     worktree.add('.')
      #     worktree.commit('chore: automated update')
      #   end
      #
      # @param work_dir [String, Pathname] path to the replacement working
      #   directory
      #
      # @return [Object] the value returned by the block
      #
      # @raise [ArgumentError] if `work_dir` does not exist on disk
      #
      # @raise [Git::Error] if `work_dir` cannot be expanded to an absolute path
      #   or cannot be entered
      #
      # @yield [repo] the repository bound to `work_dir`
      #
      # @yieldparam repo [Git::Repository] a new repository of the receiver's
      #   class bound to `work_dir`
      #
      # @yieldreturn [Object] returned as the method's return value
      #
      def with_working(work_dir)
        new_path = context_helpers_validate_path(work_dir, true)
        repo = context_helpers_derived_repository(git_work_dir: new_path.to_s)
        context_helpers_chdir(new_path.to_s) { yield repo }
      end

      # Yields a repository bound to a new temporary working directory, then
      # removes the directory and its contents
      #
      # The process working directory is changed to the temporary directory for
      # the duration of the block, as {#with_working} does, so this method is
      # not safe to call from more than one thread at a time. The directory is
      # removed unconditionally after the block exits, even if the block raises
      # an exception. The yielded repository is bound as {#with_working} binds
      # it.
      #
      # @example Write files in an isolated temporary working directory
      #   repo.with_temp_working do |scratch|
      #     File.write('scratch.txt', 'temporary content')
      #     scratch.untracked_files #=> ["scratch.txt"]
      #   end
      #
      # @return [Object] the value returned by the block
      #
      # @raise [Git::Error] if the temporary directory cannot be created or
      #   removed
      #
      # @yield [repo] the repository bound to the temporary working directory
      #
      # @yieldparam repo [Git::Repository] a new repository of the receiver's
      #   class bound to the temporary directory
      #
      # @yieldreturn [Object] returned as the method's return value
      #
      # @note The yielded repository stays bound to the temporary working
      #   directory after it is removed. Do not let it, or an object that holds
      #   it and later runs commands against the working tree, escape the
      #   block: calls that read or write the working tree then raise
      #   {Git::Error}. Reads from the object database, such as
      #   {Git::Object::AbstractObject#contents}, still work.
      #
      def with_temp_working(&)
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
        @execution_context = context_helpers_derived_context(git_index_file: new_path.to_s)
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
        @execution_context = context_helpers_derived_context(git_work_dir: new_path.to_s)
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

      # Copies this execution context with selected overrides applied
      #
      # The single place the gem derives one repository context from another.
      # {#set_index} and {#set_working} assign the result to the receiver; the
      # `with_*` helpers wrap it in a second repository instead.
      #
      # @param overrides [Hash] execution-context attributes to override
      #
      # @option overrides [String, nil] :git_index_file replacement index file path
      #
      # @option overrides [String, nil] :git_work_dir replacement working directory
      #   path
      #
      # @return [Git::ExecutionContext::Repository] the derived execution context
      #
      # @api private
      #
      def context_helpers_derived_context(**overrides)
        @execution_context.dup_with(**overrides)
      end

      # Builds a repository of the receiver's class bound to a copy of this
      # execution context with selected overrides, leaving the receiver untouched
      #
      # @param overrides [Hash] execution-context attributes to override
      #
      # @option overrides [String, nil] :git_index_file replacement index file path
      #
      # @option overrides [String, nil] :git_work_dir replacement working directory
      #   path
      #
      # @return [Git::Repository] a new repository built from the derived context
      #
      # @api private
      #
      def context_helpers_derived_repository(**overrides)
        self.class.new(execution_context: context_helpers_derived_context(**overrides))
      end
    end
  end
end
