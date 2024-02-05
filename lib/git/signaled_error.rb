# frozen_string_literal: true

require_relative 'command_line_error'

module Git
  # This error is raised when a git command exits because of an uncaught signal
  #
  # The git command executed, status, stdout, and stderr are available from this
  # object.
  #
  # @api public
  #
  class SignaledError < Git::CommandLineError; end
end
