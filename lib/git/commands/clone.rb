# frozen_string_literal: true

require 'git/commands/base'

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
    class Clone < Base
      arguments do
        literal 'clone'
        flag_option :bare
        flag_option :recursive
        flag_option :mirror
        value_option :branch
        value_option :filter
        value_option %i[origin remote]
        value_option :config, repeatable: true
        flag_option :single_branch, negatable: true, validator: ->(v) { [nil, true, false].include?(v) }
        custom_option(:depth) { |v| ['--depth', v.to_i] }
        operand :repository_url, required: true, separator: '--'
        operand :directory
        execution_option :timeout
      end

      # Execute the git clone command
      #
      # @overload call(repository_url, directory = nil, **options)
      #
      #   @param repository_url [String] the URL of the repository to clone
      #
      #   @param directory [String, nil] the directory to clone into.
      #     If nil, git derives the directory name from the repository URL.
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
      #   @option options [String] :origin (nil) Name of the remote (defaults to 'origin')
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
      # @return [Git::CommandLineResult] the result of the git clone command
      #
      # @raise [ArgumentError] if unsupported options are provided, if :single_branch is not true, false, or nil,
      #   or if any option fails validation
      #
      def call(...) = super
    end
  end
end
