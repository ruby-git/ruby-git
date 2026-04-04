# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Wrapper for the `git show` command
    #
    # Displays information about git objects (commits, annotated tags, trees,
    # or blobs). Output format varies by object type and is intended for human
    # consumption rather than machine parsing.
    #
    # @example Show the HEAD commit
    #   show = Git::Commands::Show.new(execution_context)
    #   result = show.call
    #
    # @example Show a specific commit
    #   show = Git::Commands::Show.new(execution_context)
    #   result = show.call('HEAD')
    #
    # @example Show the contents of a file at a given revision
    #   show = Git::Commands::Show.new(execution_context)
    #   result = show.call('abc123:README.md')
    #
    # @example Show multiple objects
    #   show = Git::Commands::Show.new(execution_context)
    #   result = show.call('v1.0', 'v2.0')
    #
    # @see https://git-scm.com/docs/git-show git-show documentation
    #
    # @see Git::Commands
    #
    # @api private
    #
    class Show < Git::Commands::Base
      arguments do
        literal 'show'

        # Stream stdout to this IO object instead of buffering in memory.
        # When provided, the command dispatches to the streaming execution path.
        execution_option :out

        operand :object, repeatable: true
      end

      # @!method call(*, **)
      #
      #   @overload call(*object)
      #
      #     Trailing newlines are preserved in the result stdout. Pass the result's
      #     `.stdout` to callers that need the raw object content unchanged.
      #
      #     @param object [Array<String>] zero or more object specifiers (refs, SHAs,
      #       `objectish:path` expressions, etc.)
      #
      #       When empty, defaults to `HEAD`
      #
      #     @return [Git::CommandLineResult] the result of calling `git show`;
      #       `result.stdout` will have trailing newlines preserved
      #
      #     @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      #   @overload call(*object, out:)
      #
      #     Streams stdout directly to `out` without buffering in memory.
      #     Use this form when showing large blobs to avoid memory pressure.
      #
      #     @param object [Array<String>] zero or more object specifiers
      #
      #     @param out [IO, #write] the command output is sent to the given IO object
      #
      #       Instead of being captured in the result; the result's
      #       `.stdout` will be `''` in this case.
      #
      #     @return [Git::CommandLineResult] the result of calling `git show`;
      #       `result.stdout` will be `''` — stdout was streamed to `out`
      #
      #     @raise [Git::FailedError] if git exits with a non-zero exit status

      private

      # @return [false] show output preserves trailing newlines, which are significant
      #   for blob content
      def chomp_captured_stdout? = false
    end
  end
end
