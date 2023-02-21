# frozen_string_literal: true

module Git
  # This error is raised when a git command fails
  #
  class GitExecuteError < StandardError; end
end