# frozen_string_literal: true

module Git
  # The execution context for running git commands
  #
  # This class is responsible for executing raw git commands and managing the
  # repository's environment (working directory, .git path, logger). It uses
  # the existing `Git::CommandLine` class to interact with the system's git binary.
  #
  # @api private
  #
  # This class is part of the internal implementation and should not be used
  # directly by users of the gem. For now, it's a thin wrapper around Git::Lib
  # to maintain compatibility during the architectural transition.
  #
  class ExecutionContext
    # Delegate to Git::Lib for now during the transition
    #
    # @param base [Git::Base] the base git object
    #
    def initialize(base)
      @lib = Git::Lib.new(base)
    end

    # Forward all method calls to the underlying Git::Lib instance
    def method_missing(method, ...)
      @lib.send(method, ...)
    end

    # Respond to methods that Git::Lib responds to
    def respond_to_missing?(method, include_private = false)
      @lib.respond_to?(method, include_private) || super
    end
  end
end
