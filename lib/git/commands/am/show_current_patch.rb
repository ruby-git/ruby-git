# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Am
      # Implements the `git am --show-current-patch` command
      #
      # Shows the message currently being applied when `git am` has stopped due to
      # conflicts.
      #
      # @example Show the current patch
      #   show_cmd = Git::Commands::Am::ShowCurrentPatch.new(execution_context)
      #   show_cmd.call
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-am/2.53.0
      #
      # @see Git::Commands::Am
      #
      # @see https://git-scm.com/docs/git-am git-am
      #
      # @api private
      #
      class ShowCurrentPatch < Git::Commands::Base
        arguments do
          literal 'am'
          flag_or_value_option :show_current_patch, inline: true
        end

        # @overload call(*, show_current_patch: true, **options)
        #
        #   Execute the `git am --show-current-patch` command
        #
        #   @param show_current_patch [true, String] patch format selector
        #
        #     Pass `true` (default) to emit `--show-current-patch` (git defaults to
        #     `raw` format); pass `'diff'` to emit `--show-current-patch=diff` (diff
        #     portion only) or `'raw'` for `--show-current-patch=raw` (full raw email).
        #     Passing `false` or `nil` raises `ArgumentError`.
        #
        #   @param options [Hash] command options
        #
        #   @return [Git::CommandLineResult] the result of calling
        #     `git am --show-current-patch`
        #
        #   @raise [ArgumentError] if `show_current_patch` is `false` or `nil`
        #
        #   @raise [ArgumentError] if unsupported options are provided
        #
        #   @raise [Git::FailedError] if git exits with a non-zero exit status
        #
        def call(*, show_current_patch: true, **)
          unless show_current_patch
            raise ArgumentError,
                  ":show_current_patch must be true or a non-empty String, got #{show_current_patch.inspect}"
          end

          super
        end
      end
    end
  end
end
