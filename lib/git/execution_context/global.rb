# frozen_string_literal: true

require 'git/execution_context'

module Git
  class ExecutionContext
    # Execution context for global git commands (no repository required)
    #
    # Used for commands that do not require an existing repository — such as
    # `git init`, `git clone`, and `git version`. Unlike
    # {Git::ExecutionContext::Repository}, this class leaves `GIT_DIR`,
    # `GIT_WORK_TREE`, and `GIT_INDEX_FILE` as `nil` (which unsets them), so
    # that the parent environment cannot leak an unintended repository context.
    # `GIT_SSH` is still supported to allow SSH-based remote operations
    # (e.g. `git clone git@github.com:...`).
    #
    # @example Create a context using the default git binary
    #   context = Git::ExecutionContext::Global.new
    #
    # @example Create a context targeting a specific binary
    #   context = Git::ExecutionContext::Global.new(binary_path: '/usr/local/bin/git2')
    #
    # @api private
    #
    class Global < ExecutionContext
      # Creates a new global execution context
      #
      # @example Create with default settings
      #   Git::ExecutionContext::Global.new
      #
      # @example Create with an explicit binary path
      #   Git::ExecutionContext::Global.new(binary_path: '/usr/local/bin/git2')
      #
      # @param binary_path [String, :use_global_config] path to the git binary
      #
      #   Give `:use_global_config` (the default) to use `Git::Base.config.binary_path`.
      #
      #   Passing `nil` raises `ArgumentError` — there is no "unset the
      #   binary" semantic.
      #
      # @param git_ssh [String, nil, :use_global_config] the SSH wrapper path
      #
      #   Give `nil` to unset `GIT_SSH`, or `:use_global_config` (default) to use `Git::Base.config.git_ssh`.
      #
      # @param logger [Logger, nil] the logger to use in the CommandLine layer
      #
      #   Give `nil` to use a null logger (`Logger.new(nil)`).
      #
      # @raise [ArgumentError] if `binary_path` is `nil`
      #
      def initialize(binary_path: :use_global_config, git_ssh: :use_global_config, logger: nil)
        super
      end
    end
  end
end
