# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Remote
      # Implements the `git remote` command
      #
      # Lists all configured remote connections.
      #
      # @see Git::Commands::Remote
      # @see https://git-scm.com/docs/git-remote git-remote
      #
      # @api private
      class List < Git::Commands::Base
        arguments do
          literal 'remote'
          flag_option %i[verbose v]
        end

        # @!method call(*, **)
        #
        #   @overload call(**options)
        #
        #     Execute the `git remote` command
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :verbose (nil) Show remote URLs alongside remote names
        #
        #       Alias: :v
        #
        #     @return [Git::CommandLineResult] the result of calling `git remote`
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
