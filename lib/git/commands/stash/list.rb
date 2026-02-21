# frozen_string_literal: true

require 'git/commands/base'
require 'git/parsers/stash'

module Git
  module Commands
    module Stash
      # List all stash entries
      #
      # @see Git::Commands::Stash Git::Commands::Stash for usage examples
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      #
      # @api private
      #
      # @example List all stashes
      #   Git::Commands::Stash::List.new(execution_context).call
      #
      class List < Git::Commands::Base
        arguments do
          literal 'stash'
          literal 'list'
          literal "--format=#{Git::Parsers::Stash::STASH_FORMAT}"
        end

        # @!method call(*, **)
        #
        #   List all stash entries
        #
        #   @overload call()
        #
        #     @return [Git::CommandLineResult] the result of calling `git stash list`
      end
    end
  end
end
