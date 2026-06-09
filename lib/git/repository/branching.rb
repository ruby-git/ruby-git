# frozen_string_literal: true

require 'pathname'
require 'git/branch'
require 'git/branch_info'
require 'git/branches'
require 'git/commands/branch/create'
require 'git/commands/branch/delete'
require 'git/commands/branch/list'
require 'git/commands/branch/show_current'
require 'git/commands/checkout/branch'
require 'git/commands/checkout/files'
require 'git/commands/checkout_index'
require 'git/commands/update_ref/update'
require 'git/parsers/branch'
require 'git/repository/shared_private'

module Git
  class Repository
    # Facade methods for branching operations: creating, checking out, querying,
    # deleting, and updating branches
    #
    # Included by {Git::Repository}.
    #
    # @api public
    #
    module Branching # rubocop:disable Metrics/ModuleLength
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
      # @example Get the current branch name
      #   repo.current_branch  # => "main"
      #
      # @example In detached HEAD state
      #   repo.current_branch  # => "HEAD"
      #
      # @return [String] the current branch name, or `'HEAD'` when in detached
      #   HEAD state
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      def current_branch
        result = Git::Commands::Branch::ShowCurrent.new(@execution_context).call
        name = result.stdout.strip
        name.empty? ? 'HEAD' : name
      end

      # Restore working tree files from a tree-ish
      #
      # @example Restore README.md to its HEAD state
      #   repo.checkout_file('HEAD', 'README.md')
      #
      # @param version [String] the tree-ish (branch, tag, commit SHA, etc.) to
      #   restore the file from
      #
      # @param file [String] the path to the file to restore
      #
      # @return [String] git's stdout from the checkout
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      def checkout_file(version, file)
        Git::Commands::Checkout::Files.new(@execution_context).call(version, pathspec: [file]).stdout
      end

      # Switch branches or restore working tree files
      #
      # @example Check out an existing branch
      #   repo.checkout('main')
      #
      # @example Create and check out a new branch from main
      #   repo.checkout('new-feature', new_branch: true, start_point: 'main')
      #
      # @example Create a new branch with a name different from the start point
      #   repo.checkout('main', new_branch: 'new-feature')
      #
      # @example Force checkout discarding local changes
      #   repo.checkout('main', force: true)
      #
      # @param branch [String, nil] the branch to check out; defaults to nil
      #   (i.e. restore HEAD state)
      #
      # @param opts [Hash] options for the checkout command
      #
      # @option opts [Boolean, nil] :force (nil) discard local changes when
      #   switching branches
      #
      # @option opts [Boolean, String, nil] :new_branch (nil) when `true`,
      #   creates a new branch named `branch` from `:start_point`
      #
      #   When a `String`, creates a new branch with that name, using `branch`
      #   as the start point.
      #
      # @option opts [Boolean, String, nil] :b (nil) alias for `:new_branch`
      #
      # @option opts [Boolean, nil] :f (nil) alias for `:force`
      #
      # @option opts [String, nil] :start_point (nil) the commit or branch to
      #   start the new branch from; used together with `new_branch: true`
      #
      # @return [String] git's stdout from the checkout
      #
      # @raise [ArgumentError] if unsupported options are provided
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      def checkout(branch = nil, opts = {})
        if branch.is_a?(Hash) && opts.empty?
          opts = branch
          branch = nil
        end

        SharedPrivate.assert_valid_opts!(CHECKOUT_ALLOWED_OPTS, **opts)

        target, translated_opts = Private.translate_checkout_opts(branch, opts)
        Git::Commands::Checkout::Branch.new(@execution_context).call(target, **translated_opts).stdout
      end

      # Populate the working tree from the index
      #
      # @example Check out all files from the index
      #   repo.checkout_index(all: true)
      #
      # @example Force check out a specific file
      #   repo.checkout_index(force: true, path_limiter: 'README.md')
      #
      # @example Check out files to a staging prefix
      #   repo.checkout_index(prefix: 'tmp/stage/', all: true)
      #
      # @param options [Hash] options for the checkout-index command
      #
      # @option options [Boolean, nil] :all (nil) check out all files in the index
      #
      # @option options [Boolean, nil] :force (nil) overwrite existing files
      #
      # @option options [String, nil] :prefix (nil) write files under this path prefix
      #   rather than the working directory root
      #
      # @option options [String, Pathname, Array<String, Pathname>, nil] :path_limiter (nil)
      #   limit the check out to the given path(s)
      #
      # @return [String] git's stdout from the checkout-index command
      #
      # @raise [ArgumentError] if unsupported options are provided
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      def checkout_index(options = {})
        SharedPrivate.assert_valid_opts!(CHECKOUT_INDEX_ALLOWED_OPTS, **options)

        paths = Private.normalize_pathspecs(options[:path_limiter], 'path_limiter')
        keyword_opts = options.except(:path_limiter)
        Git::Commands::CheckoutIndex.new(@execution_context).call(*paths.to_a, **keyword_opts).stdout
      end

      # Returns `true` if the named branch exists as a local branch
      #
      # @example Check whether main exists locally
      #   repo.local_branch?('main')  # => true
      #
      # @param branch [String] the local branch name to look up
      #
      # @return [Boolean] `true` if the branch exists locally, `false` otherwise
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
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
      # @example Check whether master exists on any remote
      #   repo.remote_branch?('master')  # => true
      #
      # @param branch [String] the short branch name to look up across all remotes
      #
      # @return [Boolean] `true` if a remote-tracking branch with that short name
      #   exists, `false` otherwise
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      def remote_branch?(branch)
        result = Git::Commands::Branch::List.new(@execution_context)
                                            .call("*/#{branch}", remotes: true, format: '%(refname:lstrip=3)')
        result.stdout.each_line.any? { |line| line.chomp == branch }
      end

      # Returns `true` if the named branch exists locally or as a remote-tracking branch
      #
      # @example Check whether main exists anywhere
      #   repo.branch?('main')  # => true
      #
      # @param branch [String] the branch name to look up
      #
      # @return [Boolean] `true` if the branch exists locally or remotely,
      #   `false` otherwise
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      def branch?(branch)
        local_branch?(branch) || remote_branch?(branch)
      end

      # Checks whether the named branch exists locally
      #
      # @example Check whether main exists locally
      #   repo.is_local_branch?('main')  # => true
      #
      # @param branch [String] the local branch name to look up
      #
      # @return [Boolean] `true` if the branch exists locally, `false` otherwise
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @deprecated use {#local_branch?} instead
      #
      def is_local_branch?(branch) # rubocop:disable Naming/PredicatePrefix
        Git::Deprecation.warn(
          'Git::Repository#is_local_branch? is deprecated and will be removed in a future version. ' \
          'Use Git::Repository#local_branch? instead.'
        )
        local_branch?(branch)
      end

      # Checks whether the named branch exists as a remote-tracking branch
      #
      # @example Check whether master exists on any remote
      #   repo.is_remote_branch?('master')  # => true
      #
      # @param branch [String] the short branch name to look up across all remotes
      #
      # @return [Boolean] `true` if a remote-tracking branch with that short name
      #   exists, `false` otherwise
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @deprecated use {#remote_branch?} instead
      #
      def is_remote_branch?(branch) # rubocop:disable Naming/PredicatePrefix
        Git::Deprecation.warn(
          'Git::Repository#is_remote_branch? is deprecated and will be removed in a future version. ' \
          'Use Git::Repository#remote_branch? instead.'
        )
        remote_branch?(branch)
      end

      # Checks whether the named branch exists locally or as a remote-tracking branch
      #
      # @example Check whether main exists anywhere
      #   repo.is_branch?('main')  # => true
      #
      # @param branch [String] the branch name to look up
      #
      # @return [Boolean] `true` if the branch exists locally or remotely,
      #   `false` otherwise
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @deprecated use {#branch?} instead
      #
      def is_branch?(branch) # rubocop:disable Naming/PredicatePrefix
        Git::Deprecation.warn(
          'Git::Repository#is_branch? is deprecated and will be removed in a future version. ' \
          'Use Git::Repository#branch? instead.'
        )
        branch?(branch)
      end

      # Option keys accepted by {#branch_new}
      #
      BRANCH_NEW_ALLOWED_OPTS = %i[].freeze
      private_constant :BRANCH_NEW_ALLOWED_OPTS

      # Create a new branch
      #
      # @example Create a new branch from the current HEAD
      #   repo.branch_new('feature')
      #
      # @example Create a new branch from a specific commit or branch
      #   repo.branch_new('feature', 'main')
      #
      # @param branch [String] the name of the branch to create
      #
      # @param start_point [String, nil] the commit, branch, or tag to start the
      #   new branch from; defaults to the current HEAD when `nil`
      #
      # @param options [Hash] reserved; must be empty — no options are currently
      #   supported
      #
      # @return [void]
      #
      # @raise [ArgumentError] if unsupported options are provided
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
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
      # @example Delete a single branch
      #   repo.branch_delete('feature') # => "Deleted branch feature (was abc1234)."
      #
      # @example Delete multiple branches at once
      #   repo.branch_delete('feature-1', 'feature-2')
      #
      # @example Force-delete an unmerged branch
      #   repo.branch_delete('unmerged-branch', force: true)
      #
      # @example Delete a remote-tracking branch
      #   repo.branch_delete('origin/feature', remotes: true)
      #
      # @param branches [Array<String>] the name(s) of the branch(es) to delete
      #
      # @param options [Hash] options for the delete command
      #
      # @option options [Boolean, nil] :force (true) allow deleting the branch
      #   irrespective of its merged status
      #
      #   Defaults to `true` to match the 4.x behavior.
      #
      # @option options [Boolean, nil] :remotes (nil) delete remote-tracking
      #   branches
      #
      #   Use together with a `remote/branch` name.
      #
      # @return [String] the stdout output from the delete command, e.g.
      #   `"Deleted branch feature (was abc1234)."`
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

      # Returns the `git branch --list --contains` stdout for a given commit
      #
      # The output format is the human-readable `git branch` listing: each
      # matching branch name appears on its own line, prefixed with two spaces,
      # or `* ` if it is the currently checked-out branch. This is the same
      # format returned by `Git::Lib#branch_contains` in the 4.x gem series.
      #
      # @example List all branches that contain a commit
      #   repo.branch_contains('abc1234')
      #   # => "  main\n"
      #
      # @example The current branch is marked with an asterisk
      #   repo.branch_contains('abc1234')
      #   # => "* main\n  feature\n"
      #
      # @example Limit the search to branches matching a shell wildcard pattern
      #   repo.branch_contains('abc1234', 'feature/*')
      #
      # @example Typical usage: check whether any branch contains the commit
      #   repo.branch_contains('abc1234').empty?  # => false
      #
      # @param commit [String] the commit SHA or ref to look up
      #
      # @param branch_name [String, nil] a shell wildcard pattern to limit which
      #   branches are searched
      #
      #   When empty or `nil`, all local branches are searched.
      #
      # @return [String] the `git branch --list --contains` stdout
      #
      #   Each matching branch appears on its own line, prefixed with two
      #   spaces, or `* ` for the currently checked-out branch. Returns an
      #   empty string when no matching branch contains the commit.
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      def branch_contains(commit, branch_name = '')
        branch_name = branch_name.to_s
        pattern = branch_name.empty? ? nil : branch_name
        Git::Commands::Branch::List.new(@execution_context)
                                   .call(*[pattern].compact, contains: commit, no_color: true)
                                   .stdout
      end

      # Returns all local and remote-tracking branches as structured objects
      #
      # @example List all branches
      #   repo.branches_all
      #   # => [#<data Git::BranchInfo refname="main", current=true, ...>,
      #   #     #<data Git::BranchInfo refname="remotes/origin/main", current=false, ...>]
      #
      # @example Find the currently checked-out branch
      #   repo.branches_all.find(&:current)
      #
      # @example List only local branches
      #   repo.branches_all.reject(&:remote?)
      #
      # @return [Array<Git::BranchInfo>] parsed branch information for every
      #   local and remote-tracking branch
      #
      #   Returns an empty array when the repository has no branches.
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      def branches_all
        result = Git::Commands::Branch::List.new(@execution_context).call(
          all: true, format: Git::Parsers::Branch::FORMAT_STRING
        )
        Git::Parsers::Branch.parse_list(result.stdout)
      end

      # Update a branch ref to point to a new commit
      #
      # Derives the full ref from the `branch` argument:
      #
      # - `remotes/<remote>/<name>` or `refs/remotes/<remote>/<name>` →
      #   writes to `refs/remotes/<remote>/<name>` (remote-tracking branch)
      # - Any other value → writes to `refs/heads/<branch>` (local branch)
      #
      # @example Advance a local branch to the current HEAD
      #   repo.update_ref('feature', repo.rev_parse('HEAD'))
      #
      # @example Reset a local branch to an older commit
      #   repo.update_ref('main', 'abc1234def5678')
      #
      # @example Update a remote-tracking branch ref
      #   repo.update_ref('remotes/origin/main', 'abc1234def5678')
      #
      # @param branch [String] a local or remote-tracking branch name
      #
      #   Short local names (e.g. `'main'`) resolve to `refs/heads/<branch>`.
      #   Remote-tracking names with a `remotes/<remote>/` or
      #   `refs/remotes/<remote>/` prefix (e.g. `'remotes/origin/main'`)
      #   resolve to `refs/remotes/<remote>/<name>`.
      #
      # @param commit [String] the commit SHA to point the branch at
      #
      # @return [Git::CommandLineResult] the result of calling `git update-ref`
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      def update_ref(branch, commit)
        ref = Private.build_update_ref(branch)
        Git::Commands::UpdateRef::Update.new(@execution_context).call(ref, commit)
      end

      # Returns a {Git::Branch} object for the given branch name
      #
      # @example Get a branch object for 'main'
      #   repo.branch('main')  #=> #<Git::Branch 'main'>
      #
      # @example Get a branch object for the current branch
      #   repo.branch  #=> #<Git::Branch 'main'>
      #
      # @param branch_name [String] the branch name (defaults to the current branch)
      #
      # @return [Git::Branch] the branch object
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      def branch(branch_name = current_branch)
        branch_info = Git::BranchInfo.new(
          refname: branch_name,
          target_oid: nil,
          current: false,
          worktree: false,
          symref: nil,
          upstream: nil
        )
        Git::Branch.new(self, branch_info)
      end

      # Returns a {Git::Branches} collection of all branches in the repository
      #
      # @example List all branches
      #   repo.branches
      #   # => #<Git::Branches ...>
      #
      # @example Iterate over all branches
      #   repo.branches.each { |b| puts b.name }
      #
      # @example Access local branches only
      #   repo.branches.local
      #
      # @example Access remote-tracking branches only
      #   repo.branches.remote
      #
      # @example Look up a branch by name
      #   repo.branches['main']  # => #<Git::Branch 'main'>
      #
      # @return [Git::Branches] a collection wrapping all local and
      #   remote-tracking branches in the repository
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      def branches
        Git::Branches.new(self)
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

        # Builds the full git ref string from a branch name argument
        #
        # Mirrors the routing logic of `Git::Branch#update_ref` for backward
        # compatibility:
        #
        # - `remotes/<remote>/<name>` or `refs/remotes/<remote>/<name>` →
        #   `refs/remotes/<remote>/<name>`
        # - Any other value → `refs/heads/<branch>`
        #
        # @param branch [String] a short local branch name or a remote-tracking
        #   branch name with a `remotes/` or `refs/remotes/` prefix
        #
        # @return [String] the full git ref string
        #
        # @api private
        #
        def build_update_ref(branch)
          match = branch.match(%r{\A(?:refs/)?remotes/([^/]+)/(.+)\z})
          match ? "refs/remotes/#{match[1]}/#{match[2]}" : "refs/heads/#{branch}"
        end
      end
      private_constant :Private
    end
  end
end
