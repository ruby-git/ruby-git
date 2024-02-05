# frozen_string_literal: true

require_relative 'command_line_error'

module Git
  # This error is raised when a git command returns a non-zero exitstatus
  #
  # The git command executed, status, stdout, and stderr are available from this
  # object.
  #
  # @api public
  #
  class FailedError < Git::CommandLineError; end
end
