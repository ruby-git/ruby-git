# frozen_string_literal: true

require 'git/commands/arguments'
require 'git/url'

module Git
  module Commands
    # Implements the `git clone` command
    #
    # This command clones a repository into a newly created directory.
    #
    # @api private
    #
    # @example Basic usage
    #   clone = Git::Commands::Clone.new(execution_context)
    #   result = clone.call('https://github.com/user/repo.git', 'local-dir')
    #
    # @example With options
    #   clone = Git::Commands::Clone.new(execution_context)
    #   result = clone.call('https://github.com/user/repo.git', 'local-dir', bare: true, depth: 1)
    #
    class Clone
      # Arguments DSL for building command-line arguments
      ARGS = Arguments.define do
        static 'clone'
        flag :bare
        flag :recursive
        flag :mirror
        value :branch
        value :filter
        value %i[origin remote]
        value :config, multi_valued: true
        flag :single_branch, negatable: true, validator: ->(v) { [nil, true, false].include?(v) }
        custom(:depth) { |v| ['--depth', v.to_i] }
        # Options handled by the command itself, not passed to git
        metadata :path
        metadata :timeout
        metadata :log
        metadata :git_ssh
        positional :repository_url, required: true, separator: '--'
        positional :directory
      end.freeze

      # Initialize the Clone command
      #
      # @param execution_context [Git::ExecutionContext, Git::Lib] the context for executing git commands
      #
      def initialize(execution_context)
        @execution_context = execution_context
      end

      # Execute the git clone command
      #
      # @overload call(repository_url, directory = nil, **options)
      #
      #   @param repository_url [String] the URL of the repository to clone
      #
      #   @param directory [String, nil] the directory to clone into.
      #     If nil, the directory name is derived from the repository URL.
      #
      #   @param options [Hash] command options
      #
      #   @option options [Boolean] :bare (nil) Clone as a bare repository
      #
      #   @option options [String] :branch (nil) The branch to checkout after cloning
      #
      #   @option options [String, Array<String>] :config (nil) Configuration options to set
      #
      #   @option options [Integer] :depth (nil) Create a shallow clone with the specified number of commits
      #
      #   @option options [String] :filter (nil) Specify partial clone (e.g., 'tree:0', 'blob:none')
      #
      #   @option options [String, nil] :git_ssh (nil) SSH command or binary to use for git over SSH
      #
      #   @option options [Logger] :log (nil) Logger instance to use for git operations
      #
      #   @option options [Boolean] :mirror (nil) Set up a mirror of the source repository
      #
      #   @option options [String] :origin (nil) Name of the remote (defaults to 'origin')
      #
      #   @option options [String] :path (nil) Prefix path for the clone directory
      #
      #   @option options [Boolean] :recursive (nil) Initialize submodules after cloning
      #
      #   @option options [String] :remote (nil) Alias for :origin
      #
      #   @option options [Boolean, nil] :single_branch (nil) Clone only the history
      #     leading to the tip of a single branch
      #
      #   @option options [Numeric, nil] :timeout (nil) The number of seconds to wait for
      #     the command to complete
      #
      # @return [Hash] options to pass to Git::Base.new for creating the repository object
      #
      # @raise [ArgumentError] if unsupported options are provided, if :single_branch is not true, false, or nil,
      #   or if any option fails validation
      #
      def call(*, **options)
        options = options.dup
        bound_args = ARGS.bind(*, **options)

        directory = options.delete(:path) || bound_args.directory
        directory ||= Git::URL.clone_to(
          bound_args.repository_url, bare: options[:bare], mirror: options[:mirror]
        )

        args = ARGS.bind(bound_args.repository_url, directory, **options)

        @execution_context.command(*args, timeout: options[:timeout])

        build_result(directory, options)
      end

      private

      # Build the result hash for creating a Git::Base instance
      #
      # @param clone_dir [String] the directory that was cloned to
      # @param options [Hash] the options hash
      # @return [Hash] options for Git::Base.new
      #
      def build_result(clone_dir, options)
        result = {}

        if options[:bare] || options[:mirror]
          result[:repository] = clone_dir
        else
          result[:working_directory] = clone_dir
        end

        result[:log] = options[:log] if options[:log]
        result[:git_ssh] = options[:git_ssh] if options.key?(:git_ssh)

        result
      end
    end
  end
end
