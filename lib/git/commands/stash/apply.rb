# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Stash
      # Apply stashed changes to the working directory
      #
      # Applies the changes recorded in a stash to the working tree.
      # Unlike {Pop}, this does not remove the stash from the stash list.
      #
      # @see Git::Commands::Stash Git::Commands::Stash for usage examples
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      #
      # @api private
      #
      # @example Apply the latest stash
      #   Git::Commands::Stash::Apply.new(execution_context).call
      #
      # @example Apply a specific stash
      #   Git::Commands::Stash::Apply.new(execution_context).call('stash@\\{2}')
      #
      # @example Apply and restore index state
      #   Git::Commands::Stash::Apply.new(execution_context).call(index: true)
      #
      class Apply < Git::Commands::Base
        arguments do
          literal 'stash'
          literal 'apply'
          flag_option :index
          operand :stash
        end

        # @!method call(*, **)
        #
        #   Apply stashed changes
        #
        #   @overload call(**options)
        #
        #     Apply the latest stash
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :index (nil) restore the index state as well
        #
        #   @overload call(stash, **options)
        #
        #     Apply a specific stash
        #
        #     @param stash [String] stash reference (e.g., 'stash@\\{0}', '0')
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :index (nil) restore the index state as well
        #
        #   @return [Git::CommandLineResult] the result of calling `git stash apply`
        #
        #   @raise [Git::FailedError] if the stash does not exist
      end
    end
  end
end
