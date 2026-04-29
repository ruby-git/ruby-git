# frozen_string_literal: true

require 'git/execution_context/repository'
require 'git/repository/staging'

module Git
  # The main public interface for interacting with a Git repository
  #
  # `Git::Repository` is the **orchestration layer** for all git operations. It acts
  # as the glue between the user-facing API and the underlying components, but
  # contains minimal domain logic itself. For each operation it:
  #
  # 1. **Pre-processes arguments** — transforms user-provided values into forms
  #    suitable for the command layer (e.g. path expansion, option normalization,
  #    Ruby-idiomatic defaults, deprecation handling, input validation).
  # 2. **Calls commands** — invokes one or more `Git::Commands::*` classes via the
  #    injected `Git::ExecutionContext::Repository`.
  # 3. **Builds rich return values** — passes raw command output through
  #    `Git::Parsers::*` classes and result-class factory methods to assemble the
  #    meaningful Ruby objects the caller expects.
  #
  # Some operations are genuinely one-line delegators when no pre/post-processing is
  # needed (e.g. `add`, `reset`), but many are short orchestration sequences that
  # coordinate argument preparation, one or more command calls, and result assembly.
  #
  # Facade methods are organized into focused modules under `lib/git/repository/`
  # (e.g. {Git::Repository::Staging}) and included into this class.
  #
  # @api public
  #
  class Repository
    include Git::Repository::Staging

    # @param execution_context [Git::ExecutionContext::Repository] the context used
    #   to run git commands for this repository; must not be nil
    #
    # @raise [ArgumentError] if `execution_context` is nil
    #
    def initialize(execution_context:)
      raise ArgumentError, 'execution_context must not be nil' if execution_context.nil?

      @execution_context = execution_context
    end
  end
end
