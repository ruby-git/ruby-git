# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git show` command
    #
    # Displays information about git objects (commits, annotated tags, trees,
    # or blobs). Output format varies by object type and is intended for human
    # consumption rather than machine parsing.
    #
    # @see https://git-scm.com/docs/git-show git-show documentation
    # @see Git::Commands
    #
    # @api private
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
    class Show < Git::Commands::Base
      arguments do
        literal 'show'
        operand :objects, repeatable: true
      end

      # Execute the `git show` command.
      #
      # @overload call(*objects)
      #
      #   Trailing newlines are preserved in the result stdout. Pass the result's
      #   `.stdout` to callers that need the raw object content unchanged.
      #
      #   @param objects [Array<String>] zero or more object specifiers (refs, SHAs,
      #     `objectish:path` expressions, etc.). When empty, defaults to `HEAD`.
      #
      #   @return [Git::CommandLineResult] the result of calling `git show`
      #
      #   @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      def call(*, **)
        bound = args_definition.bind(*, **)
        result = @execution_context.command_capturing(
          *bound,
          **bound.execution_options,
          chomp: false,
          raise_on_failure: false
        )
        validate_exit_status!(result)
        result
      end
    end
  end
end
