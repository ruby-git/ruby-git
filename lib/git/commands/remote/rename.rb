# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Remote
      # Implements the `git remote rename` command
      #
      # Renames a remote and updates its associated tracking branches and config sections.
      #
      # @see Git::Commands::Remote
      # @see https://git-scm.com/docs/git-remote git-remote
      #
      # @api private
      class Rename < Git::Commands::Base
        arguments do
          literal 'remote'
          literal 'rename'
          flag_option :progress, negatable: true

          end_of_options

          operand :old, required: true
          operand :new, required: true
        end

        # @!method call(*, **)
        #
        #   @overload call(old, new, **options)
        #
        #     Execute the `git remote rename` command
        #
        #     @param old [String] The current remote name
        #
        #     @param new [String] The new remote name
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :progress (nil) Control whether progress is shown during rename
        #
        #       Pass `true` for `--progress` or `false` for `--no-progress`.
        #
        #     @return [Git::CommandLineResult] the result of calling `git remote rename`
        #
        #     @raise [ArgumentError] if old or new is not provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
