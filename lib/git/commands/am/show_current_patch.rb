# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Am
      # Wrapper for the `git am --show-current-patch` command
      #
      # Shows the message currently being applied when `git am` has stopped due to
      # conflicts.
      #
      # @example Show the current patch
      #   show_cmd = Git::Commands::Am::ShowCurrentPatch.new(execution_context)
      #   show_cmd.call
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
          flag_or_value_option :show_current_patch, inline: true, type: [TrueClass, String]
        end

        # @overload call(format = true, **options)
        #
        #   Execute the `git am --show-current-patch` command
        #
        #   @param format [true, String] optional format: `'diff'` emits
        #     `--show-current-patch=diff` (diff portion only); `'raw'` emits
        #     `--show-current-patch=raw` (full raw email)
        #
        #     When omitted, emits `--show-current-patch` and git defaults to `raw`.
        #
        #   @return [Git::CommandLineResult] the result of calling `git am --show-current-patch`
        #
        #   @raise [Git::FailedError] if no am session is in progress
        #
        def call(format = true, **) # rubocop:disable Style/OptionalBooleanParameter
          super(**, show_current_patch: format)
        end
      end
    end
  end
end
