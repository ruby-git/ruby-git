# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Remote
      # Implements the `git remote update` command
      #
      # Fetches updates for one or more remotes or remote groups.
      #
      # @see Git::Commands::Remote
      # @see https://git-scm.com/docs/git-remote git-remote
      #
      # @api private
      class Update < Git::Commands::Base
        arguments do
          literal 'remote'
          flag_option %i[verbose v]
          literal 'update'
          flag_option %i[prune p]
          end_of_options
          operand :remote_or_group, repeatable: true
        end

        # @!method call(*, **)
        #
        #   @overload call(*remote_or_group, **options)
        #
        #     Execute the `git remote update` command
        #
        #     @param remote_or_group [Array<String>] Zero or more remote names or remote group names
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :verbose (nil) Show remote URLs alongside remote names
        #
        #       Alias: :v
        #
        #     @option options [Boolean] :prune (nil) Prune stale tracking refs while updating remotes
        #
        #       Alias: :p
        #
        #     @return [Git::CommandLineResult] the result of calling `git remote update`
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
