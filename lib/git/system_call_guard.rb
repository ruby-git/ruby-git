# frozen_string_literal: true

require 'git/errors'

module Git
  # Convert `SystemCallError` raised by the gem's own filesystem calls to {Git::Error}
  #
  # The gem promises to raise only `ArgumentError` or a subclass of {Git::Error}.
  # Filesystem calls such as `File.read`, `Dir.chdir`, or `Tempfile.create` can
  # raise a bare `SystemCallError` (`Errno::ENOENT`, `Errno::EACCES`, and so on).
  # Wrapping those calls in {.call} keeps the promise: the `SystemCallError` is
  # re-raised as a {Git::Error} with the original error available as `cause`.
  #
  # Helpers that yield to caller-supplied blocks must not relabel errors raised
  # by the caller's own code. {#unguarded} marks that region so a
  # `SystemCallError` raised inside it propagates unchanged.
  #
  # @example Guard a single filesystem call
  #   content = Git::SystemCallGuard.call('Failed to read the gitdir pointer file') do
  #     File.read(path)
  #   end
  #
  # @example Guard setup and cleanup but not the caller's block
  #   def with_tempfile(&block)
  #     Git::SystemCallGuard.call('Failed to create a temporary file') do |guard|
  #       Tempfile.create do |file|
  #         guard.unguarded { block.call(file) }
  #       end
  #     end
  #   end
  #
  # @api private
  #
  class SystemCallGuard
    # Run the block, converting any `SystemCallError` it raises to {Git::Error}
    #
    # @param message [String] prefix for the {Git::Error} message
    #
    # @return [Object] the value returned by the block
    #
    # @raise [Git::Error] if the block raises a `SystemCallError` outside an
    #   unguarded region
    #
    # @yield [guard] the guarded region
    #
    # @yieldparam guard [Git::SystemCallGuard] use {#unguarded} to exempt a region
    #
    # @yieldreturn [Object] returned as the method's return value
    #
    def self.call(message, &)
      new.call(message, &)
    end

    # Run the block, converting any `SystemCallError` it raises to {Git::Error}
    #
    # @param (see .call)
    #
    # @return (see .call)
    #
    # @raise (see .call)
    #
    # @yield (see .call)
    #
    # @yieldparam (see .call)
    #
    # @yieldreturn (see .call)
    #
    def call(message)
      yield self
    rescue SystemCallError => e
      raise if e.equal?(@unguarded_error)

      raise Git::Error, "#{message}: #{e.message}"
    end

    # Run the block with `SystemCallError` conversion suspended
    #
    # If the block raises a `SystemCallError`, the enclosing {#call} re-raises
    # that same error unchanged. Any other `SystemCallError` reaching {#call},
    # including one raised while unwinding from the block's error, is converted.
    #
    # @return [Object] the value returned by the block
    #
    # @yield the region exempt from conversion
    #
    # @yieldreturn [Object] returned as the method's return value
    #
    def unguarded
      yield
    rescue SystemCallError => e
      @unguarded_error = e
      raise
    end
  end
end
