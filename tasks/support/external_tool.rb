# frozen_string_literal: true

# Runs an external tool that a rake task requires and aborts the task when it cannot
#
# A tool that is not a gem cannot be supplied by `bundle install`, so a task that
# depends on one fails with an install hint rather than skipping when the tool is
# missing: a check that silently no-ops would make a successful run mean less than it
# says.
module ExternalTool
  module_function

  # Run the command, aborting the rake task when the tool cannot start or fails
  #
  # @param command [Array<String>] the tool followed by its arguments
  # @param task [String] the rake task name named in the abort messages
  # @param install_hint [String] how to install the tool, printed when it cannot start
  #
  # @return [true] when the tool exits successfully
  #
  def run(command, task:, install_hint:)
    tool = command.first
    # With `exception: true`, `system` raises Errno::ENOENT when it cannot find the tool
    # and RuntimeError when the tool runs and fails, so no separate probe for the tool
    # is needed. ENOENT also covers a tool on PATH whose interpreter is missing (a
    # broken shim), so the message reports the error rather than asserting the tool is
    # absent. Any other failure to start the tool propagates with its own error.
    system(*command, exception: true)
  rescue Errno::ENOENT => e
    abort <<~MESSAGE
      Could not start #{tool} (#{e.message}), and `rake #{task}` requires it.
      Either #{tool} is not installed or not on PATH, or the #{tool} found on PATH cannot run.
      #{install_hint.chomp}
    MESSAGE
  rescue RuntimeError
    abort "rake #{task} failed"
  end
end
