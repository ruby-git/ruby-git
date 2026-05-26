# frozen_string_literal: true

require 'pathname'
require 'git/commands/branch/create'
require 'git/commands/branch/delete'
require 'git/commands/branch/list'
require 'git/commands/branch/show_current'
require 'git/commands/checkout/branch'
require 'git/commands/checkout/files'
require 'git/commands/checkout_index'
require 'git/repository/shared_private'

module Git
  class Repository
    # Facade methods for branching operations: checking out, switching branches,
    # querying the current branch, and deleting branches
    #
    # Included by {Git::Repository}.
    #
    # @api public
    #
    module Branching
      # Option keys accepted by {#checkout}
      #
      CHECKOUT_ALLOWED_OPTS = %i[force f new_branch b start_point].freeze
      private_constant :CHECKOUT_ALLOWED_OPTS

      # Option keys accepted by {#checkout_index}
      #
      CHECKOUT_INDEX_ALLOWED_OPTS = %i[prefix force all path_limiter].freeze
      private_constant :CHECKOUT_INDEX_ALLOWED_OPTS

      # Returns the name of the current branch
      #
      # @overload current_branch()
      #
      #   @example Get the current branch name
      #     repo.current_branch  # => "main"
      #
      #   @example In detached HEAD state
      #     repo.current_branch  # => "HEAD"
      #
      #   @return [String] the current branch name, or `'HEAD'` when in detached
      #     HEAD state
      #
      #   @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      def current_branch
        result = Git::Commands::Branch::ShowCurrent.new(@execution_context).call
        name = result.stdout.strip
        name.empty? ? 'HEAD' : name
      end

      # Restore working tree files from a tree-ish
      #
      # @overload checkout_file(version, file)
      #
      #   @example Restore README.md to its HEAD state
      #     repo.checkout_file('HEAD', 'README.md')
      #
      #   @param version [String] the tree-ish (branch, tag, commit SHA, etc.) to
      #     restore the file from
      #
      #   @param file [String] the path to the file to restore
      #
      #   @return [String] git's stdout from the checkout
      #
      #   @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      def checkout_file(version, file)
        Git::Commands::Checkout::Files.new(@execution_context).call(version, pathspec: [file]).stdout
      end

      # Switch branches or restore working tree files
      #
      # @overload checkout(branch = nil, options = {})
      #
      #   @example Check out an existing branch
      #     repo.checkout('main')
      #
      #   @example Create and check out a new branch from main
      #     repo.checkout('new-feature', new_branch: true, start_point: 'main')
      #
      #   @example Create a new branch with a name different from the start point
      #     repo.checkout('main', new_branch: 'new-feature')
      #
      #   @example Force checkout discarding local changes
      #     repo.checkout('main', force: true)
      #
      #   @param branch [String, nil] the branch to check out; defaults to nil
      #     (i.e. restore HEAD state)
      #
      #   @param options [Hash] options for the checkout command
      #
      #   @option options [Boolean, nil] :force (nil) discard local changes when
      #     switching branches
      #
      #   @option options [Boolean, String, nil] :new_branch (nil) when `true`,
      #     creates a new branch named `branch` from `:start_point`; when a
      #     `String`, creates a new branch with that name from `branch`
      #
      #   @option options [Boolean, String, nil] :b (nil) alias for `:new_branch`
      #
      #   @option options [Boolean, nil] :f (nil) alias for `:force`
      #
      #   @option options [String] :start_point the commit or branch to start the
      #     new branch from; used together with `new_branch: true`
      #
      #   @return [String] git's stdout from the checkout
      #
      #   @raise [ArgumentError] when unsupported options are provided
      #
      #   @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      def checkout(branch = nil, options = {})
        if branch.is_a?(Hash) && options.empty?
          options = branch
          branch = nil
        end

        SharedPrivate.assert_valid_opts!(CHECKOUT_ALLOWED_OPTS, **options)

        target, translated_opts = Private.translate_checkout_opts(branch, options)
        Git::Commands::Checkout::Branch.new(@execution_context).call(target, **translated_opts).stdout
      end

      # Populate the working tree from the index
      #
      # @overload checkout_index(options = {})
      #
      #   @example Check out all files from the index
      #     repo.checkout_index(all: true)
      #
      #   @example Force check out a specific file
      #     repo.checkout_index(force: true, path_limiter: 'README.md')
      #
      #   @example Check out files to a staging prefix
      #     repo.checkout_index(prefix: 'tmp/stage/', all: true)
      #
      #   @param options [Hash] options for the checkout-index command
      #
      #   @option options [Boolean, nil] :all (nil) check out all files in the index
      #
      #   @option options [Boolean, nil] :force (nil) overwrite existing files
      #
      #   @option options [String] :prefix write files under this path prefix
      #     rather than the working directory root
      #
      #   @option options [String, Pathname, Array<String, Pathname>] :path_limiter
      #     limit the check out to the given path(s)
      #
      #   @return [String] git's stdout from the checkout-index command
      #
      #   @raise [ArgumentError] when unsupported options are provided
      #
      #   @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      def checkout_index(options = {})
        SharedPrivate.assert_valid_opts!(CHECKOUT_INDEX_ALLOWED_OPTS, **options)

        paths = Private.normalize_pathspecs(options[:path_limiter], 'path_limiter')
        keyword_opts = options.except(:path_limiter)
        Git::Commands::CheckoutIndex.new(@execution_context).call(*paths.to_a, **keyword_opts).stdout
      end

      # Returns `true` if the named branch exists as a local branch
      #
      # @overload local_branch?(branch)
      #
      #   @example Check whether main exists locally
      #     repo.local_branch?('main')  # => true
      #
      #   @param branch [String] the local branch name to look up
      #
      #   @return [Boolean] `true` if the branch exists locally, `false` otherwise
      #
      #   @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      def local_branch?(branch)
        result = Git::Commands::Branch::List.new(@execution_context).call(branch, format: '%(refname:short)')
        result.stdout.chomp == branch
      end

      # Returns `true` if the named branch exists as a remote-tracking branch
      #
      # The `branch` argument must be the **short branch name** (e.g. `'master'`),
      # not the combined `remote/branch` form (e.g. `'origin/master'`).
      #
      # @overload remote_branch?(branch)
      #
      #   @example Check whether master exists on any remote
      #     repo.remote_branch?('master')  # => true
      #
      #   @param branch [String] the short branch name to look up across all remotes
      #
      #   @return [Boolean] `true` if a remote-tracking branch with that short name
      #     exists, `false` otherwise
      #
      #   @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      def remote_branch?(branch)
        result = Git::Commands::Branch::List.new(@execution_context)
                                            .call("*/#{branch}", remotes: true, format: '%(refname:lstrip=3)')
        result.stdout.each_line.any? { |line| line.chomp == branch }
      end

      # Returns `true` if the named branch exists locally or as a remote-tracking branch
      #
      # @overload branch?(branch)
      #
      #   @example Check whether main exists anywhere
      #     repo.branch?('main')  # => true
      #
      #   @param branch [String] the branch name to look up
      #
      #   @return [Boolean] `true` if the branch exists locally or remotely,
      #     `false` otherwise
      #
      #   @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      def branch?(branch)
        local_branch?(branch) || remote_branch?(branch)
      end

      # Option keys accepted by {#branch_new}
      #
      BRANCH_NEW_ALLOWED_OPTS = %i[].freeze
      private_constant :BRANCH_NEW_ALLOWED_OPTS

      # Create a new branch
      #
      # @overload branch_new(branch, start_point = nil, options = {})
      #
      #   @example Create a new branch from the current HEAD
      #     repo.branch_new('feature')
      #
      #   @example Create a new branch from a specific commit or branch
      #     repo.branch_new('feature', 'main')
      #
      #   @param branch [String] the name of the branch to create
      #
      #   @param start_point [String, nil] the commit, branch, or tag to start the
      #     new branch from; defaults to the current HEAD when `nil`
      #
      #   @param options [Hash] reserved; must be empty — no options are currently
      #     supported
      #
      #   @return [void]
      #
      # @raise [ArgumentError] when unsupported options are provided
      #
      # @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      def branch_new(branch, start_point = nil, options = {})
        if start_point.is_a?(Hash) && options.empty?
          options = start_point
          start_point = nil
        end

        SharedPrivate.assert_valid_opts!(BRANCH_NEW_ALLOWED_OPTS, **options)
        Git::Commands::Branch::Create.new(@execution_context).call(branch, start_point, **options)

        nil
      end

      # Option keys accepted by {#branch_delete}
      #
      BRANCH_DELETE_ALLOWED_OPTS = %i[force remotes].freeze
      private_constant :BRANCH_DELETE_ALLOWED_OPTS

      # Delete one or more local or remote-tracking branches
      #
      # @overload branch_delete(*branches, **options)
      #
      #   @example Delete a single branch
      #     repo.branch_delete('feature') # => "Deleted branch feature (was abc1234)."
      #
      #   @example Delete multiple branches at once
      #     repo.branch_delete('feature-1', 'feature-2')
      #
      #   @example Force-delete an unmerged branch
      #     repo.branch_delete('unmerged-branch', force: true)
      #
      #   @example Delete a remote-tracking branch
      #     repo.branch_delete('origin/feature', remotes: true)
      #
      #   @param branches [Array<String>] the name(s) of the branch(es) to delete
      #
      #   @param options [Hash] options for the delete command
      #
      #   @option options [Boolean, nil] :force (true) allow deleting the branch
      #     irrespective of its merged status
      #
      #     Defaults to `true` to match the 4.x behavior.
      #
      #   @option options [Boolean, nil] :remotes (nil) delete remote-tracking
      #     branches
      #
      #     Use together with a `remote/branch` name.
      #
      #   @return [String] the stdout output from the delete command, e.g.
      #     `"Deleted branch feature (was abc1234)."`
      #
      # @raise [ArgumentError] if unsupported options are provided
      #
      # @raise [Git::FailedError] if git exits outside the allowed range (exit code > 1)
      #
      # @raise [Git::Error] if git reports a deletion failure
      #
      def branch_delete(*branches, **options)
        options = { force: true }.merge(options)
        SharedPrivate.assert_valid_opts!(BRANCH_DELETE_ALLOWED_OPTS, **options)

        result = Git::Commands::Branch::Delete.new(@execution_context).call(*branches, **options)

        raise Git::Error, result.stderr.strip unless result.status.success?

        result.stdout.strip
      end

      # Private helpers local to {Git::Repository::Branching}
      #
      # @api private
      module Private
        module_function

        # Translates legacy checkout options to the new command interface
        #
        # Legacy callers passed combinations like:
        #   checkout('branch', new_branch: true, start_point: 'main')
        # which should map to:
        #   checkout('main', b: 'branch')
        #
        # @param branch [String, nil] the branch argument passed to {#checkout}
        #
        # @param options [Hash] the raw options passed to {#checkout}
        #
        # @return [Array] a two-element tuple `[target, options]` containing the
        #   translated checkout arguments
        #
        #   `target` (`String` or `nil`) is the branch or commit to check out.
        #   `options` is a `Hash` of keyword arguments for
        #   `Git::Commands::Checkout::Branch#call`
        #
        # @api private
        #
        def translate_checkout_opts(branch, options)
          if options[:new_branch] == true || options[:b] == true
            [options[:start_point], options.except(:new_branch, :b, :start_point).merge(b: branch)]
          elsif options[:new_branch].is_a?(String)
            [branch, options.except(:new_branch).merge(b: options[:new_branch])]
          else
            [branch, options]
          end
        end

        # Normalizes path specifications for Git commands
        #
        # @param pathspecs [String, Pathname, Array<String, Pathname>, nil]
        #   the path(s) to normalize
        #
        # @param arg_name [String] the argument name used in error messages
        #
        # @return [Array<String>, nil] the normalized paths, or `nil` if none are valid
        #
        # @raise [ArgumentError] when any path is not a `String` or `Pathname`
        #
        # @api private
        #
        def normalize_pathspecs(pathspecs, arg_name)
          return nil unless pathspecs

          normalized = Array(pathspecs)
          validate_pathspec_types(normalized, arg_name)

          normalized = normalized.map(&:to_s).reject(&:empty?)
          return nil if normalized.empty?

          normalized
        end

        # Raises an error if any element of `pathspecs` is not a `String` or `Pathname`
        #
        # @param pathspecs [Array] the path elements to validate
        #
        # @param arg_name [String] the argument name used in error messages
        #
        # @return [void]
        #
        # @raise [ArgumentError] when any element is not a `String` or `Pathname`
        #
        # @api private
        #
        def validate_pathspec_types(pathspecs, arg_name)
          return if pathspecs.all? { |path| path.is_a?(String) || path.is_a?(Pathname) }

          raise ArgumentError, "Invalid #{arg_name}: must be a String, Pathname, or Array of Strings/Pathnames"
        end
      end
      private_constant :Private
    end
  end
end
