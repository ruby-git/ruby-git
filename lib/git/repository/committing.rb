# frozen_string_literal: true

require 'git/commands/commit'
require 'git/commands/commit_tree'
require 'git/commands/write_tree'
require 'git/repository/internal'

module Git
  class Repository
    # Facade methods for committing operations: recording commits, manipulating
    # tree objects, and building commit objects outside the working tree
    #
    # Included by {Git::Repository}.
    #
    # @api public
    #
    module Committing
      # Option keys accepted by {#commit}
      COMMIT_ALLOWED_OPTS = %i[
        all amend allow_empty allow_empty_message author date
        gpg_sign no_gpg_sign no_verify
      ].freeze
      private_constant :COMMIT_ALLOWED_OPTS

      # Option keys accepted by {#commit_tree}
      COMMIT_TREE_ALLOWED_OPTS = %i[parent p parents message m].freeze
      private_constant :COMMIT_TREE_ALLOWED_OPTS

      # Record staged changes as a new commit
      #
      # @overload commit(message = nil, **options)
      #
      #   @example Commit with a message
      #     repo.commit('Add README')
      #
      #   @example Amend the previous commit, reusing its message
      #     repo.commit(nil, amend: true)
      #
      #   @example Stage all modified files and commit
      #     repo.commit('Cleanup', all: true)
      #
      #   @param message [String, nil] the commit message; pass `nil` to omit
      #     (e.g. when using `:amend` to reuse the previous message)
      #
      #   @param options [Hash] options for the commit command
      #
      #   @option options [Boolean] :all (false) automatically stage modified and
      #     deleted files before committing
      #
      #   @option options [Boolean] :amend (false) replace the tip of the current
      #     branch with a new commit
      #
      #   @option options [Boolean] :allow_empty (false) allow committing with no
      #     changes
      #
      #   @option options [Boolean] :allow_empty_message (false) allow committing
      #     with an empty message
      #
      #   @option options [String] :author (nil) override the commit author in
      #     `A U Thor <author@example.com>` format
      #
      #   @option options [String] :date (nil) override the author date
      #
      #   @option options [Boolean] :gpg_sign (false) GPG-sign the commit
      #
      #   @option options [Boolean] :no_gpg_sign (false) disable GPG signing
      #
      #   @option options [Boolean] :no_verify (false) bypass the pre-commit and
      #     commit-msg hooks
      #
      #   @return [String] git's stdout from the commit
      #
      # @raise [ArgumentError] if unsupported options are provided
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      def commit(message = nil, **opts)
        if opts.key?(:add_all)
          Git::Deprecation.warn('The :add_all option for #commit is deprecated, use :all instead')
          opts[:all] = opts.delete(:add_all)
        end

        Git::Repository::Internal.assert_valid_opts!(COMMIT_ALLOWED_OPTS, **opts)

        call_opts = { no_edit: true }
        call_opts[:message] = message if message

        Git::Commands::Commit.new(@execution_context).call(**call_opts, **opts).stdout
      end

      # Commit all modified tracked files without explicitly staging them first
      #
      # Equivalent to `commit(message, all: true, **options)`.
      #
      # @overload commit_all(message, **options)
      #
      #   @example
      #     repo.commit_all('Update everything')
      #
      #   @param message [String] the commit message
      #
      #   @param options [Hash] additional options forwarded to {#commit}
      #
      #   @return [String] git's stdout from the commit
      #
      # @raise [ArgumentError] if unsupported options are provided
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      def commit_all(*, **)
        commit(*, all: true, **)
      end

      # Create a commit object from a tree SHA without moving HEAD
      #
      # Unlike {#commit}, this does not read the index; it directly wraps
      # `git commit-tree`.
      #
      # @overload commit_tree(tree, **options)
      #
      #   @example Commit a tree with a parent
      #     repo.commit_tree('deadbeef', message: 'snapshot', parent: 'HEAD')
      #
      #   @param tree [String] the tree SHA to commit
      #
      #   @param options [Hash] options for the commit-tree command
      #
      #   @option options [String] :m (nil) the commit message (short form)
      #
      #   @option options [String] :message (nil) the commit message (normalized
      #     to `:m` before passing to the command)
      #
      #   @option options [String, Array<String>] :p (nil) parent commit SHA(s)
      #
      #   @option options [String] :parent (nil) a single parent commit SHA
      #     (normalized to `:p`)
      #
      #   @option options [Array<String>] :parents (nil) multiple parent commit
      #     SHAs (normalized to `:p`)
      #
      #   @return [String] the SHA of the newly created commit object
      #
      # @raise [ArgumentError] if unsupported options are provided
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      def commit_tree(tree, **opts)
        Git::Repository::Internal.assert_valid_opts!(COMMIT_TREE_ALLOWED_OPTS, **opts)

        opts[:p] = opts.delete(:parents) if opts.key?(:parents)
        opts[:p] = opts.delete(:parent) if opts.key?(:parent)
        opts[:m] = opts.delete(:message) if opts.key?(:message)
        opts[:m] = "commit tree #{tree}" unless opts[:m]

        Git::Commands::CommitTree.new(@execution_context).call(tree, **opts).stdout
      end

      # Write the current index to a tree object in the object store
      #
      # @example
      #   tree_sha = repo.write_tree
      #
      # @return [String] the SHA of the tree object written
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      def write_tree
        Git::Commands::WriteTree.new(@execution_context).call.stdout
      end

      # Write the current index to a tree object and immediately commit it
      #
      # Combines {#write_tree} and {#commit_tree} in a single call.
      #
      # @overload write_and_commit_tree(**options)
      #
      #   @example
      #     commit_sha = repo.write_and_commit_tree(message: 'snapshot')
      #
      #   @param options [Hash] options forwarded to {#commit_tree}
      #
      #   @return [String] the SHA of the newly created commit object
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      def write_and_commit_tree(**)
        commit_tree(write_tree, **)
      end
    end
  end
end
