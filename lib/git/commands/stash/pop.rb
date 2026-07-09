# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Stash
      # Apply stashed changes and remove from stash list
      #
      # Like {Apply}, but removes the stash from the stash list after
      # applying, unless there are conflicts.
      #
      # @example Pop the latest stash
      #   Git::Commands::Stash::Pop.new(execution_context).call
      #
      # @example Pop a specific stash
      #   Git::Commands::Stash::Pop.new(execution_context).call('stash@\\{2}')
      #
      # @example Pop and restore index state
      #   Git::Commands::Stash::Pop.new(execution_context).call(index: true)
      #
      # @example Pop quietly
      #   Git::Commands::Stash::Pop.new(execution_context).call(quiet: true)
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-stash/2.53.0
      #
      # @see Git::Commands::Stash Git::Commands::Stash for usage examples
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      #
      # @api private
      #
      class Pop < Git::Commands::Base
        arguments do
          literal 'stash'
          literal 'pop'
          flag_option :index
          flag_option %i[quiet q]
          operand :stash
        end

        # @!method call(*, **options)
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean, nil] :index (nil) command option key; see overload docs
        #     for the full option list
        #
        #   @overload call(**options)
        #
        #     Pop the latest stash
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean, nil] :index (nil) restore the index state as well
        #
        #     @option options [Boolean, nil] :quiet (nil) suppress informational messages
        #
        #       Alias: :q
        #
        #     @return [Git::CommandLine::Result] the result of calling `git stash pop`
        #
        #   @overload call(stash, **options)
        #
        #     Pop a specific stash
        #
        #     @param stash [String] stash reference (e.g., 'stash@\\{0}', '0')
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean, nil] :index (nil) restore the index state as well
        #
        #     @option options [Boolean, nil] :quiet (nil) suppress informational messages
        #
        #       Alias: :q
        #
        #     @return [Git::CommandLine::Result] the result of calling `git stash pop`
        #
        #   @raise [ArgumentError] if unsupported options are provided
        #
        #   @raise [Git::FailedError] if git exits with a non-zero exit status
        #
        #   @api public
      end
    end
  end
end
