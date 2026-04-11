# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Remote
      # `git remote rename` command
      #
      # Renames a remote and updates all its remote-tracking branches and
      # configuration settings.
      #
      # @example Rename a remote
      #   rename = Git::Commands::Remote::Rename.new(execution_context)
      #   rename.call('origin', 'upstream')
      #
      # @example Rename a remote with progress reporting
      #   rename = Git::Commands::Remote::Rename.new(execution_context)
      #   rename.call('origin', 'upstream', progress: true)
      #
      # @example Suppress progress output during rename
      #   rename = Git::Commands::Remote::Rename.new(execution_context)
      #   rename.call('origin', 'upstream', progress: false)
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-remote/2.53.0
      #
      # @see Git::Commands::Remote
      #
      # @see https://git-scm.com/docs/git-remote git-remote
      #
      # @api private
      #
      class Rename < Git::Commands::Base
        arguments do
          literal 'remote'
          literal 'rename'
          flag_option :progress, negatable: true # --[no-]progress

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
        #     @param old [String] the current remote name
        #
        #     @param new [String] the new remote name
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :progress (nil) control progress reporting during rename
        #
        #       Pass `true` for `--progress` or `false` for `--no-progress`.
        #
        #     @return [Git::CommandLineResult] the result of calling `git remote rename`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
