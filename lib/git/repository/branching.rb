# frozen_string_literal: true

require 'pathname'
require 'git/commands/branch/show_current'
require 'git/commands/checkout/branch'
require 'git/commands/checkout/files'
require 'git/commands/checkout_index'
require 'git/repository/internal'

module Git
  class Repository
    # Facade methods for branching operations: checking out, switching branches,
    # and querying the current branch
    #
    # Included by {Git::Repository}.
    #
    # @api public
    #
    module Branching
      # Option keys accepted by {#checkout}
      #
      # Derived from the 4.x `CHECKOUT_OPTION_MAP` in `Git::Lib`.
      CHECKOUT_ALLOWED_OPTS = %i[force f new_branch b start_point].freeze
      private_constant :CHECKOUT_ALLOWED_OPTS

      # Option keys accepted by {#checkout_index}
      #
      # Derived from the 4.x `CHECKOUT_INDEX_OPTION_MAP` in `Git::Lib`.
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
      # @raise [Git::FailedError] if git exits with a non-zero exit status
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
      # @raise [Git::FailedError] if git exits with a non-zero exit status
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
      #   @option options [Boolean] :force (false) discard local changes when
      #     switching branches
      #
      #   @option options [Boolean, String] :new_branch (false) when `true`,
      #     creates a new branch named `branch` from `:start_point`; when a
      #     `String`, creates a new branch with that name from `branch`
      #
      #   @option options [Boolean] :b (false) alias for `:new_branch`
      #
      #   @option options [Boolean] :f (false) alias for `:force`
      #
      #   @option options [String] :start_point the commit or branch to start the
      #     new branch from; used together with `new_branch: true`
      #
      #   @return [String] git's stdout from the checkout
      #
      # @raise [ArgumentError] if unsupported options are provided
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      def checkout(branch = nil, options = {})
        if branch.is_a?(Hash) && options.empty?
          options = branch
          branch = nil
        end

        Git::Repository::Internal.assert_valid_opts!(CHECKOUT_ALLOWED_OPTS, **options)

        target, translated_opts = translate_checkout_opts(branch, options)
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
      #   @option options [Boolean] :all (false) check out all files in the index
      #
      #   @option options [Boolean] :force (false) overwrite existing files
      #
      #   @option options [String] :prefix write files under this path prefix
      #     rather than the working directory root
      #
      #   @option options [String, Pathname, Array<String, Pathname>] :path_limiter limit the check
      #     out to the given path(s)
      #
      #   @return [String] git's stdout from the checkout-index command
      #
      # @raise [ArgumentError] if unsupported options are provided
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      def checkout_index(options = {})
        Git::Repository::Internal.assert_valid_opts!(CHECKOUT_INDEX_ALLOWED_OPTS, **options)

        paths = normalize_pathspecs(options[:path_limiter], 'path_limiter')
        keyword_opts = options.except(:path_limiter)
        Git::Commands::CheckoutIndex.new(@execution_context).call(*paths.to_a, **keyword_opts).stdout
      end

      private

      # Translates legacy checkout options to the new command interface.
      #
      # Legacy callers passed combinations like:
      #   checkout('branch', new_branch: true, start_point: 'main')
      # which should map to:
      #   checkout('main', b: 'branch')
      #
      # @param branch [String, nil] the branch argument passed to {#checkout}
      # @param options [Hash] the raw options passed to {#checkout}
      # @return [Array] a two-element tuple +[target, options]+ where +target+ is
      #   the branch or commit to check out (+String+ or +nil+) and +options+ is
      #   a +Hash+ of translated keyword arguments for
      #   +Git::Commands::Checkout::Branch#call+
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

      # Normalizes path specifications for Git commands.
      #
      # @param pathspecs [String, Pathname, Array<String, Pathname>, nil]
      # @param arg_name [String] used in error messages
      # @return [Array<String>, nil]
      # @raise [ArgumentError] if any path is not a String or Pathname
      #
      def normalize_pathspecs(pathspecs, arg_name)
        return nil unless pathspecs

        normalized = Array(pathspecs)
        validate_pathspec_types(normalized, arg_name)

        normalized = normalized.map(&:to_s).reject(&:empty?)
        return nil if normalized.empty?

        normalized
      end

      # @param pathspecs [Array]
      # @param arg_name [String]
      # @raise [ArgumentError] if any element is not a String or Pathname
      #
      def validate_pathspec_types(pathspecs, arg_name)
        return if pathspecs.all? { |path| path.is_a?(String) || path.is_a?(Pathname) }

        raise ArgumentError, "Invalid #{arg_name}: must be a String, Pathname, or Array of Strings/Pathnames"
      end
    end
  end
end
