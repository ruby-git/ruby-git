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
    # @see Git::ExecutionContext#initialize for constructor parameters and
    #   their semantics
    #
    # @api private
    #
    class Global < ExecutionContext
    end
  end
end
