# frozen_string_literal: true

module Git
  class Repository
    # Internal helpers shared by `Git::Repository::*` topic modules
    #
    # Methods defined here use `module_function` so they are callable as
    # `SharedPrivate.foo(...)` from any topic module within `Git::Repository`
    # without being added to `Git::Repository`'s instance namespace via `include`.
    #
    # The constant is declared `private_constant` so it is inaccessible from
    # outside the `Git::Repository` class body; callers inside topic modules use
    # the short unqualified form `SharedPrivate.foo(...)`.
    #
    # @api private
    #
    module SharedPrivate
      module_function

      # Validate that candidate option keys are listed in `allowed`
      #
      # Used by facade methods to enforce that only documented options (those
      # named in `@option` tags) are accepted, even when the underlying command
      # class would accept more keys. This prevents silent expansion of the
      # facade's public contract.
      #
      # @example Reject an undocumented option
      #   ADD_ALLOWED_OPTS = %i[all force].freeze
      #
      #   SharedPrivate.assert_valid_opts!(ADD_ALLOWED_OPTS, bogus: true)
      #   #=> raises ArgumentError: Unknown options: bogus
      #
      # @param allowed [Array<Symbol>] the keys permitted by the facade method
      #
      # @param candidate_keywords [Hash<Symbol, Object>] the keywords to validate
      #
      # @option candidate_keywords [Object] key_name a candidate keyword value
      #
      # @return [void]
      #
      # @raise [ArgumentError] when any candidate key is not in `allowed`
      #
      def assert_valid_opts!(allowed, **candidate_keywords)
        unknown = candidate_keywords.keys - allowed
        return if unknown.empty?

        raise ArgumentError, "Unknown options: #{unknown.join(', ')}"
      end
    end

    private_constant :SharedPrivate
  end
end
