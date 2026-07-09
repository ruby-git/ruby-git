# frozen_string_literal: true

require 'git/commands/commit'
require 'git/commands/commit_tree'
require 'git/commands/write_tree'
require 'git/repository/shared_private'

module Git
  class Repository
    # Facade methods for committing operations: recording commits, manipulating
    # tree objects, and building commit objects outside the working tree
    #
    # Included by {Git::Repository}.
    #
    # @api private
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
      # @example Commit with a message
      #   repo.commit('Add README')
      #
      # @example Amend the previous commit, reusing its message
      #   repo.commit(nil, amend: true)
      #
      # @example Stage all modified files and commit
      #   repo.commit('Cleanup', all: true)
      #
      # @param message [String, nil] the commit message; pass `nil` to omit
      #   (e.g. when using `:amend` to reuse the previous message)
      #
      # @param opts [Hash] options for the commit command
      #
      # @option opts [Boolean, nil] :all (nil) automatically stage modified and
      #   deleted files before committing
      #
      # @option opts [Boolean, nil] :amend (nil) replace the tip of the current
      #   branch with a new commit
      #
      # @option opts [Boolean, nil] :allow_empty (nil) allow committing with no
      #   changes
      #
      # @option opts [Boolean, nil] :allow_empty_message (nil) allow committing
      #   with an empty message
      #
      # @option opts [String] :author (nil) override the commit author in
      #   `A U Thor <author@example.com>` format
      #
      # @option opts [String] :date (nil) override the author date
      #
      # @option opts [Boolean, String, nil] :gpg_sign (nil) GPG-sign the commit
      #
      # @option opts [Boolean, nil] :no_gpg_sign (nil) disable GPG signing
      #
      # @option opts [Boolean, nil] :no_verify (nil) bypass the pre-commit and
      #   commit-msg hooks
      #
      # @return [String] git's stdout from the commit
      #
      # @raise [ArgumentError] when unsupported options are provided
      #
      # @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      def commit(message, opts = {})
        opts = opts.dup
        if opts.key?(:add_all)
          Git::Deprecation.warn('The :add_all option for #commit is deprecated, use :all instead')
          opts[:all] = opts.delete(:add_all)
        end

        SharedPrivate.assert_valid_opts!(COMMIT_ALLOWED_OPTS, **opts)

        call_opts = { no_edit: true }
        call_opts[:message] = message if message

        Git::Commands::Commit.new(@execution_context).call(**call_opts, **opts).stdout
      end

      # Commit all modified tracked files without explicitly staging them first
      #
      # Equivalent to calling {#commit} with `all: true` merged into `opts`.
      #
      # @example Commit all changes with a message
      #   repo.commit_all('Update everything')
      #
      # @param message [String, nil] the commit message; pass `nil` to omit
      #   (e.g. when using `:amend` to reuse the previous message)
      #
      # @param opts [Hash] additional options forwarded to {#commit}
      #
      # @option opts [Boolean, nil] :all (nil) ignored because this method
      #   always commits with `all: true`
      #
      # @option opts [Boolean, nil] :amend (nil) replace the tip of the current
      #   branch with a new commit
      #
      # @option opts [Boolean, nil] :allow_empty (nil) allow committing with no
      #   changes
      #
      # @option opts [Boolean, nil] :allow_empty_message (nil) allow committing
      #   with an empty message
      #
      # @option opts [String] :author (nil) override the commit author in
      #   `A U Thor <author@example.com>` format
      #
      # @option opts [String] :date (nil) override the author date
      #
      # @option opts [Boolean, String, nil] :gpg_sign (nil) GPG-sign the commit
      #
      # @option opts [Boolean, nil] :no_gpg_sign (nil) disable GPG signing
      #
      # @option opts [Boolean, nil] :no_verify (nil) bypass the pre-commit and
      #   commit-msg hooks
      #
      # @return [String] git's stdout from the commit
      #
      # @raise [ArgumentError] when unsupported options are provided
      #
      # @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      def commit_all(message, opts = {})
        commit(message, opts.merge(all: true))
      end

      # Create a commit object from a tree SHA without moving HEAD
      #
      # Unlike {#commit}, this does not read the index; it directly wraps
      # `git commit-tree`.
      #
      # @example Commit a tree with a parent
      #   repo.commit_tree('deadbeef', message: 'snapshot', parent: 'HEAD')
      #
      # @param tree [String, nil] the tree SHA to commit; defaults to `nil`
      #
      # @param opts [Hash] options for the commit-tree command
      #
      # @option opts [String, Array<String>] :m (nil) the commit message
      #   paragraph(s) (short form)
      #
      # @option opts [String, Array<String>] :message (nil) the commit message
      #   paragraph(s) (normalized to `:m` before passing to the command)
      #
      # @option opts [String, Array<String>] :p (nil) parent commit SHA(s)
      #
      # @option opts [String] :parent (nil) a single parent commit SHA
      #   (normalized to `:p`)
      #
      # @option opts [Array<String>] :parents (nil) multiple parent commit
      #   SHAs (normalized to `:p`)
      #
      # @return [String] the SHA of the newly created commit object
      #
      # @raise [ArgumentError] when unsupported options are provided
      #
      # @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      def commit_tree(tree = nil, opts = {}) # rubocop:disable Metrics/AbcSize
        SharedPrivate.assert_valid_opts!(COMMIT_TREE_ALLOWED_OPTS, **opts)

        opts = opts.dup
        opts[:p] = opts.delete(:parents) if opts.key?(:parents)
        opts[:p] = opts.delete(:parent) if opts.key?(:parent)
        opts[:m] = opts.delete(:message) if opts.key?(:message)
        opts[:m] = "commit tree #{tree}" unless opts[:m]

        Git::Commands::CommitTree.new(@execution_context).call(tree, **opts).stdout
      end

      # Write the current index to a tree object in the object store
      #
      # @example Get the tree SHA of the current index
      #   tree_sha = repo.write_tree
      #
      # @return [String] the SHA of the tree object written
      #
      # @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      def write_tree
        Git::Commands::WriteTree.new(@execution_context).call.stdout
      end

      # Write the current index to a tree object and immediately commit it
      #
      # Combines {#write_tree} and {#commit_tree} in a single call.
      #
      # @example Commit the current index as a snapshot
      #   commit_sha = repo.write_and_commit_tree(message: 'snapshot')
      #
      # @param opts [Hash] options forwarded to {#commit_tree}
      #
      # @option opts [String, Array<String>] :m (nil) the commit message
      #   paragraph(s) (short form)
      #
      # @option opts [String, Array<String>] :message (nil) the commit message
      #   paragraph(s) (normalized to `:m` before passing to the command)
      #
      # @option opts [String, Array<String>] :p (nil) parent commit SHA(s)
      #
      # @option opts [String] :parent (nil) a single parent commit SHA
      #   (normalized to `:p`)
      #
      # @option opts [Array<String>] :parents (nil) multiple parent commit
      #   SHAs (normalized to `:p`)
      #
      # @return [String] the SHA of the newly created commit object
      #
      # @raise [ArgumentError] when unsupported options are provided
      #
      # @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      def write_and_commit_tree(opts = {})
        commit_tree(write_tree, opts)
      end
    end
  end
end
