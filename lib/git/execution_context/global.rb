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
    # @api private
    #
    class Global < ExecutionContext
      # Creates a new global execution context
      #
      # @param git_ssh [String, nil, :use_global_config] SSH wrapper path, `nil` to
      #   unset `GIT_SSH`, or `:use_global_config` (default) to inherit from
      #   {Git::Base.config}
      #
      # @param logger [Logger, nil] logger forwarded to the CommandLine layer;
      #   `nil` uses a null logger (see {Git::ExecutionContext#initialize})
      #
      def initialize(git_ssh: :use_global_config, logger: nil)
        super
      end
    end
  end
end
