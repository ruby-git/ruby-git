# frozen_string_literal: true

require 'git/commands/options'
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
      # Options DSL for building command-line arguments
      OPTIONS = Options.define do
        flag :bare
        flag :recursive
        flag :mirror
        value :branch
        value :filter
        value %i[origin remote]
        multi_value :config
        negatable_flag :single_branch, validator: ->(v) { [nil, true, false].include?(v) }
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
      # @param repository_url [String] the URL of the repository to clone
      # @param directory [String, nil] the directory to clone into
      #
      #   If nil, the directory name is derived from the repository URL.
      #
      # @param options [Hash] command options
      #
      # @option options [Boolean] :bare Clone as a bare repository
      # @option options [String] :branch The branch to checkout after cloning
      # @option options [String, Array<String>] :config Configuration options to set
      # @option options [Integer] :depth Create a shallow clone with the specified number of commits
      # @option options [String] :filter Specify partial clone (e.g., 'tree:0', 'blob:none')
      # @option options [String, nil] :git_ssh SSH command or binary to use for git over SSH
      # @option options [Logger] :log Logger instance to use for git operations
      # @option options [Boolean] :mirror Set up a mirror of the source repository
      # @option options [String] :origin Name of the remote (defaults to 'origin')
      # @option options [String] :path Prefix path for the clone directory
      # @option options [Boolean] :recursive Initialize submodules after cloning
      # @option options [String] :remote Alias for :origin
      # @option options [Boolean, nil] :single_branch Clone only the history leading to the tip of a single branch
      # @option options [Numeric, nil] :timeout The number of seconds to wait for the command to complete
      #
      # @return [Hash] options to pass to Git::Base.new for creating the repository object
      #
      # @raise [ArgumentError] if unsupported options are provided, if :single_branch is not true, false, or nil,
      #   or if any option fails validation
      #
      def call(repository_url, directory = nil, options = {})
        options = options.dup
        directory = options.delete(:path) if options[:path]
        directory ||= Git::URL.clone_to(repository_url, bare: options[:bare], mirror: options[:mirror])

        args = OPTIONS.build(repository_url, directory, **options)

        @execution_context.command('clone', *args, timeout: options[:timeout])

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
