# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Stash
      # Remove a stash entry from the stash list
      #
      # Removes a single stash entry from the list of stash entries.
      # If no stash reference is given, it removes the latest one.
      #
      # @example Drop the latest stash
      #   Git::Commands::Stash::Drop.new(execution_context).call
      #
      # @example Drop a specific stash
      #   Git::Commands::Stash::Drop.new(execution_context).call('stash@\\{2}')
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-stash/2.53.0
      #
      # @see Git::Commands::Stash Git::Commands::Stash for usage examples
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      #
      # @api private
      #
      class Drop < Git::Commands::Base
        arguments do
          literal 'stash'
          literal 'drop'
          flag_option %i[quiet q]
          operand :stash
        end

        # @!method call(*)
        #
        #   Drop a stash entry
        #
        #   @overload call(**options)
        #
        #     Drop the latest stash
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean, nil] :quiet (nil) suppress informational messages
        #
        #       Alias: :q
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #   @overload call(stash, **options)
        #
        #     Drop a specific stash
        #
        #     @param stash [String] stash reference (e.g., 'stash@\\{0}', '0')
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean, nil] :quiet (nil) suppress informational messages
        #
        #       Alias: :q
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #   @return [Git::CommandLineResult] the result of calling `git stash drop`
        #
        #   @raise [Git::FailedError] if git exits with a non-zero exit status
        #
        #   @api public
      end
    end
  end
end
