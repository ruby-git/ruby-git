# frozen_string_literal: true

require_relative 'error'

module Git
  # This error is raised when a git command fails
  #
  # This error class is used as an alias for Git::Error for backwards compatibility.
  # It is recommended to use Git::Error directly.
  #
  # @deprecated Use Git::Error instead
  #
  GitExecuteError = Git::Error
end