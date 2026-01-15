# frozen_string_literal: true

module Git
  # The main public interface for interacting with a Git repository
  #
  # This class will serve as a clean, high-level facade for all common git
  # operations. Its methods will be simple, one-line calls that delegate the
  # actual work to appropriate command objects.
  #
  # During the architectural transition (Phase 1-2), this class remains empty.
  # In Phase 3, it will be populated with facade methods that delegate to
  # Git::Commands::* objects, and eventually replace Git::Base as the primary
  # public interface.
  #
  # @api public
  #
  class Repository # rubocop:disable Lint/EmptyClass
    # This class is intentionally empty during Phase 1 of the redesign.
    # It will be populated with methods in Phase 3.
  end
end
