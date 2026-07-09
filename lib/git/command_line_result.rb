# frozen_string_literal: true

require 'git/command_line/result'
require 'git/deprecation'

# The Git module provides a Ruby interface to Git version control.
module Git
  # Intercept the first lookup of the deprecated `Git::CommandLineResult` constant
  #
  # When `name` is `:CommandLineResult`, caches and returns {Git::CommandLine::Result}
  # after emitting a deprecation warning. Calls `super` for any other unknown constant,
  # preserving normal Ruby `NameError` behaviour.
  #
  # @param name [Symbol] the name of the missing constant
  #
  # @return [Class] the resolved constant value
  #
  # @api private
  def self.const_missing(name)
    return super unless name == :CommandLineResult

    # Cache the constant first so subsequent accesses are zero-cost even if
    # the deprecation behavior raises (e.g. in the test suite).
    const_set(:CommandLineResult, Git::CommandLine::Result)
    Git::Deprecation.warn(
      'Git::CommandLineResult is deprecated and will be removed in v6.0.0. ' \
      'Use Git::CommandLine::Result instead.'
    )
    Git::CommandLine::Result
  end
end
